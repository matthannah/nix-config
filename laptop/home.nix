{ config, pkgs, ... }:

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
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    curl
    git
    git-crypt
    gnumake
    gnupg
    google-chrome
    htop
    haskellPackages."stylish-haskell"
    haskellPackages.hlint
    iotop
    jq
    networkmanagerapplet
    nmap
    oh-my-zsh
    postgresql_10
    slack
    source-code-pro
    terminator
    tldr
    unzip
    vlc
    vscode
    xclip
    xscreensaver
    zip
  ];

  fonts.fontconfig.enableProfileFonts = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  home.file.".ghci".text = ''
    :set prompt "\ESC[34mλ> \ESC[m"
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

  programs.vim = let
    tsx = pkgs.vimUtils.buildVimPlugin {
      name = "vim-jsx-typescript";
      src = pkgs.fetchgit {
        url = "https://github.com/peitalin/vim-jsx-typescript";
        rev = "671befd0f585534fad7d319ed250f6a4c952efbb";
        sha256 = "1x9cvnmcl9bm5pqjr7lh44586zwdd73dmry6dicy93gj9nkdlc0y";
      };
    };
    loadPlugin = plugin: ''
      set rtp^=${plugin.rtp}
      set rtp+=${plugin.rtp}/after
    '';
    plugins = with pkgs.vimPlugins; [
      ctrlp
      gruvbox
      haskell-vim
      typescript-vim
      tsx
      vim-airline
      vim-airline-themes
      vim-gitgutter
      vim-json
      vim-markdown
      vim-nix
      vim-trailing-whitespace
    ];
  in {
    inherit plugins;
    enable = true;
    settings = {
      number = true; # show line numbers
    };
    extraConfig = ''
      " Workaround for broken handling of packpath by vim8/neovim for ftplugins
      " https://github.com/NixOS/nixpkgs/issues/39364
      filetype off | syn off
      ${builtins.concatStringsSep "\n"
        (map loadPlugin plugins)}
      filetype indent plugin on | syn on

      syntax on
      filetype plugin indent on
      set termguicolors
      colorscheme gruvbox
      set background=dark

      " haskell-vim syntax highlighting
      let g:haskell_enable_quantification = 1   " to enable highlighting of `forall`
      let g:haskell_enable_recursivedo = 1      " to enable highlighting of `mdo` and `rec`
      let g:haskell_enable_arrowsyntax = 1      " to enable highlighting of `proc`
      let g:haskell_enable_pattern_synonyms = 1 " to enable highlighting of `pattern`
      let g:haskell_enable_typeroles = 1        " to enable highlighting of type roles
      let g:haskell_enable_static_pointers = 1  " to enable highlighting of `static`
      let g:haskell_backpack = 1                " to enable highlighting of backpack keywords

      " Configure airline plugin
      let g:airline_theme='gruvbox'
      let g:airline_powerline_fonts = 1

      " Configure gitgutter
      set updatetime=200
    '';
  };

  services.redshift = {
    enable = true;
    latitude = "-37.7688";
    longitude = "145.0423";
    tray = false;
  };

  services.unclutter.enable = true;

  # Forward a connection to a postgres container.
  # TODO: Start container automatically and get its ip?
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


  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
    path = https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;
  };
}
