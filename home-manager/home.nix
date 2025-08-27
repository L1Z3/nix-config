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
  pathToSecrets = "${config.home.homeDirectory}/nix/secrets";
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
    paths = [(pkgs.python311Full.withPackages (ppkgs: []))];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/python3.11" --prefix ${wrapPrefix} : "${pythonldlibpath}"
    '';
  };
  desktopWrapper = import ./modules/add-desktop-file-with-icon.nix {inherit pkgs;};
in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes

    # enable declarative flatpak support
    inputs.nix-flatpak.homeManagerModules.nix-flatpak

    # enable prebuilt indexes for nix-index
    inputs.nix-index-database.homeModules.nix-index

    # theme/modding spotify
    inputs.spicetify-nix.homeManagerModules.default

    # home-manager settings for GNOME
    # (import ./modules/gnome-settings.nix (args // {inherit secrets;}))

    # home-manager settings for Plasma 6
    # (import ./modules/plasma-settings (args // {inherit secrets;}))

    # home-manager settings for hyprland
    #(import ./modules/hyprland-settings (args // {inherit secrets;}))
    ./modules/hyprland-settings

    (import ./programs/vscode (args
      // {
        inherit secrets;
        extensions = inputs.nix-vscode-extensions.extensions.${pkgs.system};
      }))
    ./programs/htop
    ./programs/syncplay
    ./programs/winapps.nix
    ./modules/neovim
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
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.dev-packages
      outputs.overlays.master-packages
      outputs.overlays.krisp-discord-fix-packages
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
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

  # The general thing seems to be that if you want home-manager to manage
  # a program's config, use it as`programs.whatever` or `services.whatever`.
  # If you just want it available, stick it in packages.
  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
      shellAliases = {
        ls = "eza -ga --git"; # modern ls alternative (default -g parameter to make `ls -lah` show groups)
        l = "eza -gal --git";
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
        # TODO add commands to remove old system/home-manager generations
        nix-cleanup-all = "sudo nix-collect-garbage --delete-old";
        nix-cleanup-aggressive = "sudo nix-collect-garbage --delete-older-than 1d";
        nix-cleanup-relaxed = "sudo nix-collect-garbage --delete-older-than 30d";
        # xdg-open is a descriptive but also annoying name
        open = "xdg-open";
        # cs300 stuff
        cs300d = "pushd $HOME/Classes/Semester08/TACS300/DEV-ENV/ && ./cs300-run-docker && popd";
        cs300o = "cd $HOME/Classes/Semester08/TACS300/DEV-ENV/home";
        cs1515d = "pushd $HOME/Classes/Semester08/CS1515/DEV-ENV/ && ./cs1515-run-docker && popd";
        cs1515o = "cd $HOME/Classes/Semester08/CS1515/DEV-ENV/home";
      };
      profileExtra = ''
        # add .profile things here
      '';
      initExtra =
        ''
          # add .bashrc things here
          # for some reason home.sessionPath is not always applying... also add it here
          export PATH="$HOME/.local/bin:$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

          watch-ep() {
            export MAIN_DIR="/run/media/liz/storage/TV Shows/"
            export BACKUP_DIR="/home/liz/mnt/drive_storage/TV Shows/"
            export SHOW_DIR="El Internado"
            export CURRENT_PATTERN="El Internado $1 \[\d+\]\.mp4"
            export MPV_DEFAULT_ARGS="--osd-bar-align-y=0.97 --volume=68 --save-position-on-quit"

            pushd "$MAIN_DIR/$SHOW_DIR"
            export FILE=$(\ls -1 2>/dev/null | grep -P -m1 "$CURRENT_PATTERN")
            if [ -n "$FILE" ]; then
                qpwgraph &
                mpv $MPV_DEFAULT_ARGS "$FILE"
            else
                popd
                pushd "$BACKUP_DIR/$SHOW_DIR"
                export FILE=$(\ls -1 2>/dev/null | grep -P -m1 "$CURRENT_PATTERN")
                if [ -n "$FILE" ]; then
                    qpwgraph &
                    mpv $MPV_DEFAULT_ARGS "$FILE"
                else
                    popd >/dev/null 2>&1
                    echo "Error: Episode '$1' not found in either directory."
                    return 1
                fi
            fi
            popd
          }

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


          duplicacy-do-mount() {
            local secrets_file="${pathToSecrets}/duplicacy-b2-mount-secrets.txt.enc"
            local mount_path="${config.home.homeDirectory}/mnt/duplicacy-backup/"
            local storage_url="b2://duplicacy-jones1167"

            # Ensure mount directory exists
            mkdir -p "$mount_path"

            # Create a subshell to contain environment variables
            (
              # Decrypt the file and read the three lines into variables
              # This will prompt for the decryption password
              {
                read -r DUPLICACY__MOUNTSTORAGE_PASSWORD
                read -r DUPLICACY__MOUNTSTORAGE_B2_ID
                read -r DUPLICACY__MOUNTSTORAGE_B2_KEY
              } < <(${pkgs.openssl}/bin/openssl enc -in "$secrets_file" -d -aes-256-cbc -pbkdf2)

              # Check if decryption was successful
              if [ $? -ne 0 ]; then
                echo "Error: Failed to decrypt secrets file."
                return 1
              fi

              # Set up trap BEFORE exporting variables
              trap 'unset DUPLICACY__MOUNTSTORAGE_PASSWORD DUPLICACY__MOUNTSTORAGE_B2_ID DUPLICACY__MOUNTSTORAGE_B2_KEY' EXIT INT TERM

              # Export the variables so duplicacy-mount can access them
              export DUPLICACY__MOUNTSTORAGE_PASSWORD
              export DUPLICACY__MOUNTSTORAGE_B2_ID
              export DUPLICACY__MOUNTSTORAGE_B2_KEY

              # Run duplicacy-mount with the environment variables
              ${pkgs.duplicacy-mount}/bin/duplicacy-mount mount-storage "$storage_url" "$mount_path" -e -flat
            )
          }
        ''
        + secrets.bashInitExtra;
    };
    firefox = {
      enable = true;
      package = pkgs.unstable.firefox;
      # support for PWAs
      nativeMessagingHosts = [pkgs.master.firefoxpwa];
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

    # themed spotify
    spicetify = let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        shuffle
        loopyLoop
      ];
    };
  };

  # Add stuff for your user as you see fit:
  home.enableNixpkgsReleaseCheck = true;
  home.packages = with pkgs; [
    # basic command line tools
    psmisc
    fastfetch
    lsof
    tldr

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
        extraPkgs = pkgs: [pkgs.qt6.full fuse3];
      })
    ffmpeg-full
    patchedpython
    # python311Full
    unstable.rustup
    samply
    # audiorelay # custom package
    unstable.rclone
    sshfs

    # android tools
    android-tools
    adbfs-rootless # better reliability than mtp for android file transfer/management

    # firefox, from programs.firefox
    pkgs.master.firefoxpwa
    # ungoogled-chromium
    chromium

    # editors and git stuff
    sublime4
    vim
    # neovim, via modules/neovim
    # jetbrains really does not play well with a declarative setup. let's just use toolbox and rely on nix-ld
    unstable.jetbrains-toolbox
    git-filter-repo
    unstable.gitkraken
    # vscode, via programs/vscode

    # media
    # spotify # using spicetify-nix instead
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
    kdePackages.kdenlive
    glaxnimate # optional dependency for kdenlive
    blender
    calibre
    pavucontrol

    # system tools
    unstable.qpwgraph
    # easyeffects
    gparted
    ntfs3g
    exfatprogs
    etcher # custom package, since it's not in repos anymore
    # TODO needs non-declarative configs due to sensitive data, try to find workaround
    duplicacy-web # custom package, since it was never merged into nixpkgs
    duplicacy-mount # my own custom package, since it's a fork. allows mounting duplicacy backups as a filesystem
    wireshark
    httrack
    # piavpn
    # binaryninja
    # fastx-client # silly little custom package # TODO upstream
    anydesk
    parsec-bin

    moonlight-qt
    warpinator-fixed # patched version to add pillow TODO upstream
    # rustdesk

    # messaging
    # vesktop
    # (pkgs.discord.override {
    #   # withVencord = true;
    # })
    # discord
    # discord PR to fix krisp on linux https://github.com/NixOS/nixpkgs/pull/424232
    krisp-fix.discord
    slack
    # slack-cli # TODO currently manually installed into ~/.local/share/slack, i should move this
    unstable.discordchatexporter-desktop
    unstable.discordchatexporter-cli

    # office, etc
    unstable.libreoffice
    # notion-app-enhanced # custom package to fix issue (TODO upstream this)
    obsidian
    xournalpp

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
    olympus
    # yuzu # custom package pulling archived last AppImage
    citra-qt # custom package pulling archived last AppImage
    celeste64
    dolphin-emu
    # unstable.godot_4

    # googleearth-pro
    nix-tree
    qalculate-gtk

    wev
    usbutils
    lshw
    evtest
  ];

  # flatpaks
  services.flatpak = {
    enable = true;
    packages = [
      "org.telegram.desktop"
      "com.github.tchx84.Flatseal"
      "org.zulip.Zulip"
      "com.steamgriddb.SGDBoop"
      # "com.rustdesk.RustDesk"
      # so many things are broken on nix zoom right now, so flatpak it is
      "us.zoom.Zoom"
      # "org.x.Warpinator"
      # "org.gnome.Evolution"
      "dev.bambosh.UnofficialHomestuckCollection"
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
    "googleearth-pro-7.3.6.10201"
    "qtwebengine-5.15.19"
  ];

  # Extra variables to add to PATH
  home.sessionPath = [
    # put PATH things here
    "$HOME/.local/bin"
    # make jetbrains toolbox happy
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    # put variables here
  };

  services.activitywatch = {
    enable = true;
    package = pkgs.unstable.aw-server-rust;
    watchers = {
      awatcher = {
        package = pkgs.unstable.awatcher;
      };
    };
  };

  xdg.desktopEntries = {
    fod-frp = {
      name = "fod frp";
      # TODO move this toml file to store if possible (though it contains sensitive data so idk how)
      exec = "frpc -c /home/liz/.config/frp-configs/fod-frpc-p2p.toml";
      terminal = true;
    };
  };

  # arRPC for vesktop
  # services.arrpc.enable = true;

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
      ExecStart = "${pkgs.unstable.rclone}/bin/rclone mount --vfs-links --vfs-cache-mode full --vfs-cache-max-size 20G --vfs-cache-min-free-space 2G drive_crypt: ${mount_directory}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -zu ${mount_directory}";
      Restart = "on-failure";
      RestartSec = 30;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.services.rclone-shared-gdrive = let
    mount_directory = "${config.home.homeDirectory}/mnt/shared_drive_storage";
  in {
    Unit = {
      Description = "Automount google drive folder using rclone";
      AssertPathIsDirectory = mount_directory;
      Wants = "network-online.target";
      After = "network-online.target";
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.unstable.rclone}/bin/rclone mount --vfs-cache-mode full --vfs-cache-max-size 5G --vfs-cache-min-free-space 2G shared_crypt: ${mount_directory}";
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
