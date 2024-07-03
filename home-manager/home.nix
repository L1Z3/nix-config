# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
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
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
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
    bash = {
      enable = true;
      shellAliases = {
        neofetch = "fastfetch";
        rebuild = "sudo nixos-rebuild switch";
        subl = "sublime4";
        apply = "$HOME/nix/home-manager/scripts/apply.sh";
      };
      profileExtra = ''
        # add .profile things here
      '';
      initExtra = ''
        # add .bashrc things here
      '';
    };
    git.enable = true;
    home-manager.enable = true;
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [
    alejandra
    adw-gtk3
    vim
    wget
    curl
    htop
    fastfetch
    sublime4
    mpv
    vlc
    spotify
    vesktop
    mcaselector
    prismlauncher
    audacity
    handbrake
    gparted
    gimp
    desktop-file-utils
    qpwgraph
    jq
  ];

  # required for some package
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  # fix dark mode in gtk3 apps
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
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

  xdg = {
    enable = true;
    mime.enable = true;
    systemDirs.data = [
      # Help Gnome find home-manager-installed apps
      "$HOME/.nix-profile/share/applications"
      "$HOME/testmeowmeowmeowmeow"
    ];
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
