# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  nixpkgs = import ./nixpkgs.nix;
  integrityPath = "/home/matt/projects/lisa/test/integrity";
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Lisa integrity.
      "${integrityPath}/module.nix"
    ];

  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  nix.useSandbox = "relaxed";

  nix.maxJobs = 1;

  nix.binaryCaches = [
    "https://cache.nixos.org/"
    "https://build.daiseelabs.com"
  ];

  nix.binaryCachePublicKeys = [
    "build.daiseelabs.com-1:dcDJ5/wXMie1xvW/o5TfedvVIqKG77i3dpKfamBJg8M="
  ];

  nixpkgs.overlays = [
    (import "${integrityPath}/overlay.nix")
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Better responsiveness during builds!
  boot.kernel.sysctl."vm.swappiness" = 10;
  zramSwap = {
    enable = true;
    memoryPercent = 40;
  };
  fileSystems."/".options = [ "noatime" ];
  fileSystems."/boot".options = [ "noatime" ];
  services.fstrim.enable = true;
  nix.daemonNiceLevel = 5;

  # Tell nixos we have a LUKS encrypted partition that needs to be
  # decrypted before we can access any LVM partitions.
  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/nvme0n1p2";
      preLVM = true;
      # Enable TRIM, lose some deniability
      allowDiscards = true;
    }
  ];

  # Containers config start.
  containers.pg = {
    # bindMounts."/home" = { hostPath = "/data/pg-container"; isReadOnly = false; };
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    config = { config, lib, pkgs, ... }: with lib; {
      boot.isContainer = true;
      networking.useDHCP = false;
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        authentication = "host all all 0.0.0.0/0 trust";
      };
      services.postgresql.package = pkgs.postgresql_10;
      networking.firewall.allowedTCPPorts = [ 5432 ];
    };
  };

  containers.es = {
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.12";
    config = { config, lib, pkgs, ... }: with lib; {
      boot.isContainer = true;
      nixpkgs.config.allowUnfree = true;
      networking.useDHCP = false;
      services.elasticsearch = {
        enable = true;
        listenAddress = "0.0.0.0";
        # transport must be on a loopback device
        extraConf = ''
          transport.host: localhost
        '';
        port = 9200;
        tcp_port = 9300;
      };

      services.kibana = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 5601;
      };

      networking.firewall.allowedTCPPorts = [ 9200 9300 5601 ];
    };
  };

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-+" ];
  networking.nat.externalInterface = "192.168.100.10";
  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
  # Containers config end.

  hardware = {
    nvidia.modesetting.enable = true;
    nvidia.optimus_prime.enable = true;
    nvidia.optimus_prime.nvidiaBusId = "PCI:1:0:0";
    nvidia.optimus_prime.intelBusId = "PCI:0:2:0";
    bluetooth.enable = true;
    enableAllFirmware = true;
    opengl.driSupport32Bit = true;
  };

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Wireguard config start.
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.10/32" ];
    privateKeyFile = "/home/matt/wg-matt.key";
    peers = [
      {
        endpoint = "build-vpn.daiseelabs.com:8083";
        publicKey = "DgFLw//BuU60Y+NMmnQ9D3kS1qDCqt4CB+Ep8yunZHs=";
        allowedIPs = [ "10.200.0.0/16" "10.100.0.0/24" "10.1.0.0/16" "10.2.0.0/16" "10.6.0.0/16" ];
        persistentKeepalive = 25;
      }
    ];
  };
  networking.hosts."10.6.3.236" = [ "lisa-acme.daiseelabs.com" ];

  systemd.services.network-reach-global = {
    description = "Monitor access to global Internet";
    # Wait for network manager to declare network "online"
    # (whatever that means)
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # preStart check to prevent dependency flapping
    # No timeout, rely on TimeoutStartSec
    preStart = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      /run/wrappers/bin/ping -c1 1.1.1.1
    '';
    script = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      while /run/wrappers/bin/ping -c1 -W2 1.1.1.1; do sleep 25s; done
      exit 1
    '';
    serviceConfig = {
      TimeoutStartSec = "1s";
      RestartSec = "1s";
      Restart = "always";
      StartLimitInterval = "0";
    };
  };
  # https://github.com/NixOS/nixpkgs/issues/30459
  systemd.services.wireguard-wg0 = {
    requires = [ "network-reach-global.service" ];
    after = [ "network-reach-global.service" ];
    # This feels backwards, but it's a useful way to
    # restart a oneshot service. "after" does the
    # expected thing.
    # https://github.com/systemd/systemd/issues/2582
    wantedBy = [ "network-reach-global.service" ];
  };
  # Wireguard config end.

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl
    exfat
    file
    git
    ncat
    nix-prefetch-scripts
    vim
    which
  ];

  nixpkgs.config.allowUnfree = true;

  programs.integrity = {
    enableWrapper = true;
    enableInsecureNixBuilds = true;

    # Current nixpkgs doesn't have ghc844, so use the known-good binary
    package = (import "${integrityPath}/test.nix" {}).binary;
  };

  # Power management for laptop.
  powerManagement.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable network manager.
  networking.networkmanager.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.videoDrivers = [ "nvidia" ];

  services.xserver.displayManager.sddm.enable = true;

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Disable touchpad when mouse connected.
  services.xserver.libinput.sendEventsMode = "disabled-on-external-mouse";

  # Reverse scrolling.
  services.xserver.libinput.naturalScrolling = true;

  # Enable the KDE Desktop Environment.
  services.xserver.desktopManager = {
    default = "xfce";
    xfce.enable = true;
  };

  # Resolve conflict between KDE and XFCE modules
  environment.variables.GDK_PIXBUF_MODULE_FILE = pkgs.lib.mkForce "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";

  # Virtualbox.
  # virtualisation.virtualbox.host.enable = true;

  # Docker.
  # virtualisation.docker.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.matt = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" "integrity" /*"vboxusers" "docker"*/ ];
    group = "users";
    home = "/home/matt";
    isNormalUser = true;
    shell = pkgs.zsh;
    uid = 1000;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
