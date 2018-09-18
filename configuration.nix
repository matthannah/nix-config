# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  nixpkgs = import ./nixpkgs.nix;

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

   nix.nixPath = [
    "nixpkgs=${nixpkgs}"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tell nixos we have a LUKS encrypted partition that needs to be
  # decrypted before we can access any LVM partitions.
  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/nvme0n1p2";
      preLVM = true;
    }
  ];

  hardware = {
    nvidia.modesetting.enable = true;
    nvidia.optimus_prime.enable = true;
    nvidia.optimus_prime.nvidiaBusId = "PCI:1:0:0";
    nvidia.optimus_prime.intelBusId = "PCI:0:2:0";
    bluetooth.enable = true;
    enableAllFirmware = true;
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    coreutils
    glxinfo
    lshw
    nix-prefetch-scripts
    pciutils
    vim
    which
  ];

  nixpkgs.config.allowUnfree = true;

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

  services.xserver.videoDrivers = ["nvidia"];
  
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

  virtualisation.virtualbox.host.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.matt = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" "vboxusers" ];
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
  system.stateVersion = "18.03"; # Did you read the comment?

}
