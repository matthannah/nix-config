# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <unstable> {};
  integrityPath = "/home/matt/projects/lisa.all/test/integrity";
in {
  # Lisa integrity overlay.
  nixpkgs.overlays = [ (import "${integrityPath}/overlay.nix") ];

  nix.binaryCaches = [
    "https://cache.nixos.org/"
    # "https://build.daiseelabs.com"
  ];
  nix.binaryCachePublicKeys = [
    # "build.daiseelabs.com-1:dcDJ5/wXMie1xvW/o5TfedvVIqKG77i3dpKfamBJg8M="
  ];
  nix.extraOptions = ''
    narinfo-cache-negative-ttl = 120
  '';
  nix.maxJobs = 1;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Lisa integrity.
      "${integrityPath}/module.nix"
    ];

  boot.initrd.luks.devices = {
    root = {
      name = "root";
      device = "/dev/disk/by-uuid/1acae0be-6263-4118-9192-cbb102172b39";
      preLVM = true;
    };
  };
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Documentation man pages
  documentation.dev.enable = true;  
  
  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";
  time.hardwareClockInLocalTime = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    coreutils
    exfat
    file
    libheif # HEIC Pictures
    manpages
    ntfs3g
    vim
  ];

  # Wireguard config start.
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.10/32" ];
    privateKeyFile = "/home/matt/wg-matt.key";
    peers = [
      {
        endpoint = "build-vpn.daiseelabs.com:8083";
        publicKey = "DgFLw//BuU60Y+NMmnQ9D3kS1qDCqt4CB+Ep8yunZHs=";
        allowedIPs = [
	  # build, dev
          "10.100.0.0/24" "10.1.0.0/16" "10.6.0.0/16"
          # demo
          "10.200.10.0/23"
	  # unsure
	  "192.168.96.0/19" "192.168.128.0/19" "192.168.160.0/19"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  networking.wireguard.interfaces.wg1 = {
    ips = [ "10.101.0.40/32" ];
    privateKeyFile = "/home/matt/wg-matt-prod.key";
    peers = [
      {
        publicKey = "qIc7ga58nKfsTADXmUseATUF5NKWeFqQAV9os1vn6mU=";
        allowedIPs = [ "10.101.0.0/24" "10.3.0.0/16" "10.4.0.0/16" ];
        endpoint = "13.238.76.249:8083";
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

  # https://github.com/NixOS/nixpkgs/issues/30459
  systemd.services.wireguard-wg1 = {
    requires = [ "network-reach-global.service" ];
    after = [ "network-reach-global.service" ];
    # This feels backwards, but it's a useful way to
    # restart a oneshot service. "after" does the
    # expected thing.
    # https://github.com/systemd/systemd/issues/2582
    wantedBy = [ "network-reach-global.service" ];
  };

  # Wireguard config end.

  # Lisa integrity.
  programs.integrity = {
    enableWrapper = true;
    enableInsecureNixBuilds = true;

    # package = (import "${integrityPath}/test.nix" {}).binary;
  };

  # Allow lisa integrity test container to run. Since it sets '__noChroot' to 'true'
  nix.useSandbox = "relaxed";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the Desktop Environment.
  services.xserver.desktopManager = {
    default = "xfce";
    xfce.enable = true;
  };

  # Tailscale VPN
  services.tailscale.enable = true;

  virtualisation.docker = {
    enable = true;
    package = unstable.docker;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.matt = {
    createHome = true;
    extraGroups = ["wheel" "video" "audio" "disk" "networkmanager" "integrity" "docker"];
    group = "users";
    home = "/home/matt";
    isNormalUser = true;
    shell = pkgs.zsh;
    uid = 1000;
  };

  # Enable virtualbox.
  virtualisation.virtualbox = {
    host.enable = true;
    guest.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}

