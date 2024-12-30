# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
} @ args: let
  # TODO currently "secrets" are just secrets from GitHub; they are not securely stored on this machine
  #      for actual secrets (e.g. passwords, etc), consider storing them some other way
  secrets = inputs.secrets.secrets;
  pythonldlibpath = lib.makeLibraryPath (with pkgs; [
    zlib
    zstd
    stdenv.cc.cc
    curl
    openssl
    attr
    libssh
    bzip2
    libxml2
    acl
    libsodium
    util-linux
    xz
    systemd
  ]);
  # Darwin requires a different library path prefix
  wrapPrefix =
    if (!pkgs.stdenv.isDarwin)
    then "LD_LIBRARY_PATH"
    else "DYLD_LIBRARY_PATH";
  patchedpython = pkgs.symlinkJoin {
    name = "python";
    paths = [pkgs.python311Full];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/python3.11" --prefix ${wrapPrefix} : "${pythonldlibpath}"
    '';
  };
  desktopWrapper = import ./modules/add-desktop-file-with-icon.nix {inherit pkgs;};
in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # enable declarative flatpak support
    inputs.nix-flatpak.homeManagerModules.nix-flatpak

    # enable prebuilt indexes for nix-index
    inputs.nix-index-database.hmModules.nix-index

    # pass secrets to gnome-settings module
    (import ./gnome-settings.nix (args // {inherit secrets;}))
    (import ./programs/vscode (args // {extensions = inputs.nix-vscode-extensions.extensions.${pkgs.system};}))
    ./programs/htop
    ./programs/syncplay
    ./programs/winapps.nix
  ];

  # TODO list:
  #   make PRs for duplicacy-mount(?), notion-app-enhanced, and maybe after some effort making it clean, duplicacy-web
  #   try my hand at packaging virtualhere and making a PR for it
  #   try out fancy riced terminal setups
  #   fix macos vm
  #   try finishing packaging easytether, piavpn
  #   figure out better development package workflow than just adding to home.packages and home-manager switching
  #   refactor home-manager/programs to use options that are enabled in home.nix
  #   find a way to make winapps install declarative

  nixpkgs = {
    # You can add overlays here
    overlays =
      [
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.unstable-packages
        outputs.overlays.dev-packages
        # If you want to use overlays exported from other flakes:
        # neovim-nightly-overlay.overlays.default

        # Or define it inline, for example:
        # (final: prev: {
        #   hi = final.hello.overrideAttrs (oldAttrs: {
        #     patches = [ ./change-hello-to-hi.patch ];
        #   });
        # })
      ]
      # add on master packages if I have it enabled
      ++ (
        if outputs.overlays ? master-packages
        then [outputs.overlays.master-packages]
        else []
      );
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
      # allow netflix in chromium
      chromium = {
        enableWideVine = true;
      };
    };
  };

  home = {
    username = "liz";
    homeDirectory = "/home/liz";
  };
  # set user icon
  # requires that /var/lib/AccountsService/users/$USER has Icon field pointing to $HOME/.face (which is default)
  # (if user icon was previously set by gnome gui, the Icon field will be set to /var/lib/AccountsService/icons/$USER; in this case
  # delete the file or change the Icon field in /var/lib/AccountsService/users/$USER to point to $HOME/.face)
  # also, this requires users.${user}.homeMode to be at least 711 so gdm can access this file
  home.file.".face".source = ../media/madeline.jpg;

  # The general thing seems to be that if you want home-manager to manage
  # a program's config, use it as`programs.whatever` or `services.whatever`.
  # If you just want it available, stick it in packages.
  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
      shellAliases = {
        ls = "eza -g --git"; # modern ls alternative (default -g parameter to make `ls -lah` show groups)
        neofetch = "fastfetch -c neofetch";
        subl = "sublime4";
        # TODO potentially make thing to automatically add aliases for scripts in scripts dir?
        # script to apply and commit nix changes
        apply = "$HOME/nix/home-manager/scripts/apply.sh";
        # update system
        update-all = "$HOME/nix/home-manager/scripts/update-all.sh";
        # update secrets repo
        update-secrets = "$HOME/nix/home-manager/scripts/update-secrets.sh";
        # list package changes in last home-manager generation
        diff-home = "nix store diff-closures $(ls -t1d $HOME/.local/state/nix/profiles/home-manager-*-link | head -2 | tac)";
        # list package changes in all home-manager generations
        diff-home-all = "nix profile diff-closures --profile ~/.local/state/nix/profiles/home-manager";
        # list package changes in last system generation
        diff-sys = "nix store diff-closures $(ls -t1d /nix/var/nix/profiles/system-*-link | head -2 | tac)";
        # list package changes in all system generations
        diff-sys-all = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
        # TODO figure out a better way to document frequently used commands; currently just throwing them in an alias so i remember they exist
        dconf-watch = "dconf watch /";
        # TODO add commands to remove old system/home-manager generations
        nix-cleanup-all = "sudo nix-collect-garbage --delete-old";
        nix-cleanup-aggressive = "sudo nix-collect-garbage --delete-older-than 1d";
        nix-cleanup-relaxed = "sudo nix-collect-garbage --delete-older-than 30d";
        duplicacy-do-mount = "mkdir -p ${config.home.homeDirectory}/mnt/duplicacy-backup/ && ${pkgs.duplicacy-mount}/bin/duplicacy-mount mount-storage b2://duplicacy-jones1167 ${config.home.homeDirectory}/mnt/duplicacy-backup/ -e -flat";
      };
      profileExtra = ''
        # add .profile things here
      '';
      initExtra =
        ''
          # add .bashrc things here

          # use nix-locate (from programs.nix-index.enable) to find .so files within nixpkgs
          find-so() {
            nix-locate "$1" | grep -v "^("
          }

          # typing "nix shell nixpkgs#..." every time to use flake-based nix shell is annoying
          # nix-qs (i.e. nix-quick-shell) will just expand to the version with nixpkgs# in front of each package
          nix-qs() {
            if [ "$#" -eq 0 ]; then
              echo "Usage: nix-qs <packages>"
              return 1
            fi

            local packages=()

            for pkg in "$@"; do
              packages+=("nixpkgs#$pkg")
            done

            # Run `nix shell` with the transformed arguments
            nix shell "$''\{packages[@]}"
          }
        ''
        + secrets.bashInitExtra;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
      # support for PWAs
      nativeMessagingHosts = [pkgs.unstable.firefoxpwa];
    };
    git = {
      enable = true;
      userName = "Elizabeth Jones";
      userEmail = "10276179+L1Z3@users.noreply.github.com";
      extraConfig = {
        submodule.recurse = true;
        init.defaultBranch = "main";
      };
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        input-overlay
        obs-vkcapture
        obs-pipewire-audio-capture
      ];
    };

    # index nixpkgs for files/missing commands
    # invoke `nix-index` to update index, invoke `nix-locate` to manually find something
    nix-index = {
      enable = true;
      enableBashIntegration = true;
    };

    # direnv, a tool for automatically loading environments per directory (integrates with nix)
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };

  # Add stuff for your user as you see fit:
  programs.neovim.enable = true;
  home.enableNixpkgsReleaseCheck = true;
  home.packages = with pkgs; [
    # basic command line tools
    psmisc
    fastfetch
    lsof

    # misc command line tools
    nix-tree
    unstable.eza
    jq
    alejandra
    dconf2nix
    unstable.yt-dlp
    frp
    # htop, via programs/htop
    (appimage-run.override
      {
        extraPkgs = pkgs: [pkgs.qt6.full];
      })
    ffmpeg-full
    patchedpython
    # python311Full
    unstable.rustup
    samply
    # audiorelay # custom package

    # android tools
    android-tools
    adbfs-rootless # better reliability than mtp for android file transfer/management

    # firefox, from programs.firefox
    pkgs.unstable.firefoxpwa
    # ungoogled-chromium
    chromium

    # editors and git stuff
    sublime4
    vim
    # have decided that declarative plugins don't work great for jetbrains
    # TODO just switch to jetbrains toolbox sometime... these take forever to build and are a pain
    unstable.jetbrains.pycharm-professional
    unstable.jetbrains.idea-ultimate
    unstable.jetbrains.clion
    unstable.jetbrains.rust-rover
    git-filter-repo
    unstable.gitkraken
    # vscode, via programs/vscode

    # media
    spotify
    mpv
    # override for vlc 3.0.20 to fix av1/opus issue temporarily
    (let
      pkgs-old-vlc = import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/0c19708cf035f50d28eb4b2b8e7a79d4dc52f6bb.tar.gz";
        sha256 = "sha256:0ngw2shvl24swam5pzhcs9hvbwrgzsbcdlhpvzqc7nfk8lc28sp3";
      }) {system = pkgs.system;};
    in
      pkgs-old-vlc.vlc)
    handbrake
    audacity
    gimp
    deluge
    # syncplay, via programs/syncplay
    stremio
    # disable for now
    # davinci-resolve-studio-patched # TODO can we pin this to a nixpkgs commit so it doesn't take 10 years to build every time
    kdenlive
    glaxnimate # optional dependency for kdenlive
    blender
    calibre
    pavucontrol

    # system tools
    unstable.qpwgraph
    # easyeffects
    gparted
    etcher # custom package, since it's not in repos anymore
    # TODO needs non-declarative configs due to sensitive data, try to find workaround
    duplicacy-web # custom package, since it was never merged into nixpkgs
    duplicacy-mount # my own custom package, since it's a fork. allows mounting duplicacy backups as a filesystem
    wireshark
    httrack
    # piavpn
    binaryninja
    # fastx-client # silly little custom package # TODO upstream
    anydesk

    # messaging
    vesktop
    slack
    # slack-cli # TODO currently manually installed into ~/.local/share/slack, i should move this

    # office, etc
    unstable.libreoffice
    notion-app-enhanced # custom package to fix issue (TODO upstream this)
    obsidian
    xournalpp
    # TODO fix screen sharing
    unstable.zoom-us

    # game stuff
    unstable.prismlauncher
    (desktopWrapper.mkDesktopWrappedPackage {
      name = "mcaselector";
      iconUrl = "https://raw.githubusercontent.com/Querz/mcaselector/cbeff376929070f27514113943a34349fdc3cc43/installer/img/small.bmp";
      iconSha256 = "sha256-YRvDfJZBWq0b/lfLXlachWHhlqrzFiwTr0e7/1fAjqQ=";
      desktopFileText = ''
        [Desktop Entry]
        Type=Application
        Name=MCA Selector
        Exec=${unstable.mcaselector}/bin/mcaselector
        Icon=mcaselector
        Terminal=false
        Categories=Game;
      '';
      targetPackage = unstable.mcaselector;
    })
    nbt-explorer # custom package
    olympus # TODO currently custom, switch to upstream nixpkgs when ready
    # yuzu # custom package pulling archived last AppImage
    citra-qt # custom package pulling archived last AppImage
    celeste64
    dolphin-emu
    unstable.godot_4

    googleearth-pro
  ];

  # flatpaks
  services.flatpak = {
    enable = true;
    packages = [
      "org.telegram.desktop"
      "com.github.tchx84.Flatseal"
      "org.zulip.Zulip"
      "com.steamgriddb.SGDBoop"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
    uninstallUnmanaged = true;

    overrides = {
      # "org.telegram.desktop".Context = {
      #   filesystems = [
      #
      #   ];
      # };
    };
  };

  # garbage collect for home-manager generations
  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 7d";
    # persistent = true; # not available until home-manager for 24.11
  };

  # required for some package
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w" # for sublime
    "googleearth-pro-7.3.6.9796"
  ];

  gtk = {
    enable = true;
    # gnome dark theme for gtk apps
    # disabled in favor of dconf since this setting causes color accents extension to fail
    # theme = {
    #   name = "Adwaita-dark";
    #   package = pkgs.gnome.gnome-themes-extra;
    # };
    # idk if this is necessary, but a line like this was in settings.ini before i did gtk.enable
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # Extra variables to add to PATH
  home.sessionPath = [
    # put PATH things here
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    # put variables here
  };

  # TODO re-enable in future; all wayland watchers seem pretty broken right now
  # services.activitywatch = {
  #   enable = true;
  #   package = pkgs.dev.aw-server-rust; # TODO update to 0.13.1 and PR
  #   watchers = {
  #     awatcher = {
  #       package = pkgs.master.awatcher; # TODO switch to unstable
  #     };
  #   };
  # };

  xdg.desktopEntries = {
    fod-frp = {
      name = "fod frp";
      # TODO move this toml file to store if possible (though it contains sensitive data so idk how)
      exec = "frpc -c /home/liz/.config/frp-configs/fod-frpc-p2p.toml";
      terminal = true;
    };
  };

  # arRPC for vesktop
  services.arrpc.enable = true;

  # easyeffects systemd service
  # (as oppossed to .config/autostart like the built-in easyeffects option does)
  # services.easyeffects = {
  #   enable = true;
  #   preset = "\"Noise + Gain\"";
  # };

  # duplicacy backup service
  # (this relies on out-of-nix duplicacy configs)
  systemd.user.services.duplicacy = {
    Unit = {
      Description = "Duplicacy";
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "${pkgs.duplicacy-web}/bin";
      ExecStart = "${pkgs.duplicacy-web}/bin/duplicacy-web -background";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # rclone gdrive crypt mount service
  # note: this relies on out-of-nix rclone configs
  # TODO can we store rclone config (maybe in secrets repo)?
  systemd.user.services.rclone-gdrive = let
    mount_directory = "${config.home.homeDirectory}/mnt/drive_storage";
  in {
    Unit = {
      Description = "Automount google drive folder using rclone";
      AssertPathIsDirectory = mount_directory;
      Wants = "network-online.target";
      After = "network-online.target";
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.rclone}/bin/rclone mount --vfs-cache-mode full drive_crypt: ${mount_directory}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -zu ${mount_directory}";
      Restart = "on-failure";
      RestartSec = 30;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
