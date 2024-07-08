# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./gnome-settings.nix
    ./programs/vscode
    ./programs/htop
    ./programs/syncplay
  ];
  # TODO list:
  #   figure out how to set profile image for gnome user
  #   setup virt-manager
  #   make PRs for duplicacy-mount(?), notion-app-enhanced, and maybe after some effort making it clean, duplicacy-web
  #   get repo in ready state for pushing to github (ensure no sensitive data, squash commit messages, etc)
  #   fix telegram desktop tray icon

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
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
    };
  };

  # TODO: Set your username
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
        neofetch = "fastfetch";
        subl = "sublime4";
        # TODO potentially make thing to automatically add aliases for scripts in scripts dir?
        # script to apply and commit nix changes
        apply = "$HOME/nix/home-manager/scripts/apply.sh";
        # update system
        update-all = "$HOME/nix/home-manager/scripts/update-all.sh";
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
      initExtra = ''
        # add .bashrc things here
        # ssh to brown
        sshb() {
            #do things with parameters like $1 such as
            if [ $# -eq 0 ]
              then
              ssh REDACTED@REDACTED
              else
              ssh -t REDACTED@REDACTED host="$1"
            fi

        }
      '';
    };
    git = {
      enable = true;
      userName = "Elizabeth Jones";
      userEmail = "10276179+L1Z3@users.noreply.github.com";
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        input-overlay
      ];
    };
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.enableNixpkgsReleaseCheck = true;
  home.packages = with pkgs; [
    # misc command line tools
    jq
    alejandra
    fastfetch
    dconf2nix
    unstable.yt-dlp
    frp
    # htop, via programs/htop

    # browsers
    firefox
    ungoogled-chromium

    # editors and git stuff
    sublime4
    vim
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
    vlc
    handbrake
    audacity
    gimp
    deluge
    # syncplay, via programs/syncplay
    stremio

    # system tools
    qpwgraph
    gparted
    etcher # custom package, since it's not in repos anymore
    # TODO needs non-declarative configs due to sensitive data, try to find workaround
    duplicacy-web # custom package, since it was never merged into nixpkgs
    duplicacy-mount # my own custom package, since it's a fork
    wireshark

    # messaging
    vesktop
    telegram-desktop

    # office, etc
    libreoffice
    notion-app-enhanced # custom package to fix issue (TODO upstream this)
    obsidian
    xournalpp

    # game stuff
    unstable.prismlauncher
    unstable.mcaselector # TODO maybe try adding custom .desktop file
    nbt-explorer # custom package
    olympus # TODO currently custom, switch to upstream nixpkgs when ready
  ];

  # garbage collect for home-manager generations
  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 30d";
    # persistent = true; # not available until home-manager for 24.11
  };

  # required for some package
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w" # for sublime
  ];

  gtk = {
    enable = true;
    # gnome dark theme for gtk apps
    # disabled in favor of dconf since this setting causes color accents extension to fail
    # theme = {
    #   name = "Adwaita-dark";
    #   package = pkgs.gnome.gnome-themes-extra;
    # };
  };

  # Extra variables to add to PATH
  home.sessionPath = [
    # put PATH things here
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    # nix-ld stuff
    # NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
    # NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    # put variables here
  };

  # TODO re-enable in future; all wayland watchers seem pretty broken right now
  # services.activitywatch = {
  #   enable = true;
  #   package = pkgs.aw-server-rust;
  #   watchers = {
  #     awatcher = {
  #       package = pkgs.awatcher;
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

  # duplicacy backup service
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
