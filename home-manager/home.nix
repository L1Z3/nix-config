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
        rebuild = "sudo nixos-rebuild switch";
        subl = "sublime4";
        # script to apply and commit nix changes
        apply = "$HOME/nix/home-manager/scripts/apply.sh";
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
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
      ];
    };
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.enableNixpkgsReleaseCheck = true;
  home.packages = with pkgs; [
    jq
    alejandra
    fastfetch
    vim

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
    deluge
    libreoffice

    mcaselector
    unstable.prismlauncher
    nbt-explorer # custom package
    etcher
  ];

  # required for some package
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w" # for sublime
  ];

  # fix dark mode in gtk3 apps
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
    # caps lock backspace remap, plus double shift to caps lock
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["shift:both_capslock" "lv3:ralt_switch" "caps:backspace"];
    };
  };

  # Extra variables to add to PATH
  home.sessionPath = [
    # put PATH things here
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    # put variables here
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
