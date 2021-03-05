{ config, pkgs, ... }:
let
  unstable = import <unstable> {};
  # Can't figure out how to escape substitution ${} when we have PROMPT='${ret_status}'.
  retStatus = ''''${ret_status}'';
  zshCustom = pkgs.writeTextFile {
    name = "zsh-custom";
    text = ''
      local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"

      if [[ -v IN_NIX_SHELL ]]; then
          PROMPT='${retStatus} %{$fg_bold[green]%}nix-shell %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
      else
          PROMPT='${retStatus} %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
      fi

      ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
      ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
      ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
      ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
    '';
    destination = "/themes/robbyrussell.zsh-theme";
  };
in {
  home.packages = with pkgs; [
    clamav # anti-virus, required to be HIPAA compliant for WFH
    curl
    discord
    unstable.docker-compose
    git
    git-crypt
    gnumake
    godot
    google-chrome
    haskellPackages."stylish-haskell"
    haskellPackages.hlint
    htop
    moreutils
    networkmanagerapplet
    ncat
    oh-my-zsh
    postgresql_10
    signal-desktop
    slack
    stack
    terminator
    unzip
    vlc
    vscode
    xclip
    xscreensaver
    zip
    zoom-us
  ];

  home.file.".ghci".text = ''
    :set prompt "\ESC[93mλ> \ESC[m"
  '';

  home.username = "matt";
  home.homeDirectory = "/home/matt";

  manual.manpages.enable = false;

  programs.zsh = {
    enable = true;
    shellAliases = {
      ns = "nix-shell --command 'zsh'";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
      custom = "${zshCustom}";
      theme = "robbyrussell";
    };
  };

  programs.git = {
    enable = true;
    userName = "Matt Hannah";
    userEmail = "matt.hannah@daisee.com";
    aliases.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    extraConfig.core.editor = "${pkgs.vim}/bin/vim";
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

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
    path = https://github.com/rycee/home-manager/archive/release-20.09.tar.gz;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
