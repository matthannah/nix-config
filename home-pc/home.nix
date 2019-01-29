{config, pkgs, ...}:

let
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
    audacity
    curl
    gimp
    git
    git-crypt
    gnumake
    gnupg
    google-chrome
    htop
    networkmanagerapplet
    ncat
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

  home.file.".ghci".text = ''
    :set prompt "\ESC[93mλ > \ESC[m"
  '';

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

  systemd.user.services.postgres-forward = {
    Unit.Description = "Forward PostgreSQL connections on local socket to container";
    Install.WantedBy = [ "graphical-session.target" ];
    Service =
      let
        script = pkgs.writeShellScriptBin "postgres.sh" ''
          rm -f ${socket}
          exec ${pkgs.nmap}/bin/ncat -lkU ${socket} --sh-exec '${pkgs.nmap}/bin/ncat 192.168.100.11 5432'
        '';
        socket = "/tmp/.s.PGSQL.5432";
      in {
        ExecStart = "${pkgs.bash}/bin/bash ${script}/bin/postgres.sh";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -f ${socket}";
      };
  };

  programs.home-manager = {
    enable = true;
    path = https://github.com/rycee/home-manager/archive/release-18.09.tar.gz;
  };
}
