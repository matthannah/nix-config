{config, pkgs, ...}:

let

  unstablePkgs = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs-channels";
    rev = "a8c71037e041725d40fbf2f3047347b6833b1703";
    sha256 = "1z4cchcw7qgjhy0x6mnz7iqvpswc2nfjpdynxc54zpm66khfrjqw";
  }) {};

  hie-nix = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "domenkozar";
    repo = "hie-nix";
    rev = "8f04568aa8c3215f543250eb7a1acfa0cf2d24ed";
    sha256 = "06ygnywfnp6da0mcy4hq0xcvaaap1w3di2midv1w9b9miam8hdrn";
  }) {};

in {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    audacity
    curl
    emacs
    libffi # Foreign function interface library (python bindings use them)
    git
    git-crypt
    gnumake
    gnupg
    google-chrome
    hie-nix.hie82
    htop
    networkmanagerapplet
    nmap
    nodePackages.node2nix
    oh-my-zsh
    postgresql
    slack
    unstablePkgs.stack
    terminator
    unzip
    virtualbox
    vlc
    vscode
    xclip
    xscreensaver
    zip
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  programs.zsh.enable = true;

  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
    ];
    theme = "robbyrussell";
  };

  programs.git = {
    enable = true;
    userName = "Matt Hannah";
    userEmail = "matt.hannah@daisee.com";
    aliases.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
  };

  services.redshift = {
    enable = true;
    latitude = "-37.7688";
    longitude = "145.0423";
    tray = false;
  };

  systemd.user.timers.kill-hie = {
    Install.WantedBy = [ "graphical-session.target" ];
    Timer = {
      OnActiveSec = "1m";
      OnUnitActiveSec= "1m";
    };
  };

  systemd.user.services.kill-hie = {
    Unit.Description = "Prevent hie from eating all the RAM";
    Install.WantedBy = [ "graphical-session.target" ];
    Service.ExecStart =
      let
        script = pkgs.writeShellScriptBin "kill-hie.sh" ''
          pid=$(${pkgs.procps}/bin/ps --no-headers -o pid,%mem -C hie | ${pkgs.gawk}/bin/awk '$2 > 60 {print $1}')
          [ -n "$pid" ] && ${pkgs.coreutils}/bin/kill $pid || true
        '';
      in "${pkgs.bash}/bin/bash ${script}/bin/kill-hie.sh";
  };

  services.unclutter.enable = true;

  programs.home-manager = {
    enable = true;
    path = https://github.com/rycee/home-manager/archive/release-18.03.tar.gz;
  };
}
