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
    ./fixes/gnome-app-install-fix.nix
    ./gnome-custom-keybinds.nix
    ./dconf.nix
    ./programs/vscode/vscode.nix
  ];

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
        # script to apply and commit nix changes
        apply = "$HOME/nix/home-manager/scripts/apply.sh";
        # update system
        update-all = "$HOME/nix/home-manager/scripts/update.sh";
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
      };
      profileExtra = ''
        # add .profile things here
      '';
      initExtra = ''
        # add .bashrc things here
      '';
    };
    git = {
      enable = true;
      userName = "Elizabeth Jones";
      userEmail = "10276179+L1Z3@users.noreply.github.com";
    };
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.enableNixpkgsReleaseCheck = true;
  home.packages =
    (with pkgs; [
      jq
      alejandra
      fastfetch
      vim
      git-filter-repo
      dconf2nix
      unstable.yt-dlp

      adw-gtk3
      sublime4
      mpv
      vlc
      handbrake
      audacity
      gparted
      gimp
      qpwgraph
      gnome.dconf-editor

      spotify
      vesktop
      telegram-desktop
      deluge
      libreoffice
      notion-app-enhanced # custom package to fix issue (TODO upstream this)
      obsidian
      gitkraken

      steam
      unstable.mcaselector # TODO maybe try adding custom .desktop file
      unstable.prismlauncher
      nbt-explorer # custom package
      etcher # custom package, since it's not in repos anymore
    ])
    ++ (with pkgs.gnomeExtensions; [
      advanced-alttab-window-switcher
      appindicator
      blur-my-shell
      clipboard-history
      focused-window-d-bus
      impatience
      steal-my-focus-window
      tiling-assistant
    ]);

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

  # gnome dark theme for gtk apps
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
