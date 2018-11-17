{config, pkgs, ...}:

{
  home.packages = with pkgs; [
    audacity
    curl
    git
    git-crypt
    gnumake
    gnupg
    google-chrome
    htop
    networkmanagerapplet
    oh-my-zsh
    postgresql
    slack
    terminator
    unzip
    vlc
    vscode
    xclip
    xscreensaver
    zip
  ];


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

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  services.redshift = {
    enable = true;
    latitude = "-37.7688";
    longitude = "145.0423";
    tray = false;
  };

  services.unclutter.enable = true;

  programs.home-manager.enable = true;
  programs.home-manager.path = https://github.com/rycee/home-manager/archive/master.tar.gz;
}
