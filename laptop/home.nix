{config, pkgs, ...}:

let
  unstable = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs-channels";
    rev = "80738ed9dc0ce48d7796baed5364eef8072c794d";
    sha256 = "0anmvr6b47gbbyl9v2fn86mfkcwgpbd5lf0yf3drgm8pbv57c1dc";
  }) {};
in {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    curl
    git
    git-crypt
    gnumake
    gnupg
    unstable.google-chrome
    htop
    networkmanagerapplet
    nmap
    oh-my-zsh
    postgresql100
    slack
    terminator
    unzip
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

  home.file.".ghci".text = ''
    :set prompt "\ESC[34mλ> \ESC[m"
  '';

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

  services.unclutter.enable = true;

  programs.home-manager = {
    enable = true;
    path = https://github.com/rycee/home-manager/archive/release-18.03.tar.gz;
  };
}
