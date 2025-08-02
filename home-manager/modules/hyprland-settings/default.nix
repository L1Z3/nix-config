{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  thisDir = "${config.home.homeDirectory}/nix/home-manager/modules/hyprland-settings";
  # TODO maybe re-enable these when ready for more automatic way of generating things from this
  # additionalConfigsTargetDir = "hypr/configs/";
  # additionalConfigsSrcDir = "configs/"
  # additionalConfigs = ["main.conf"];

  # packages to be installed + available as their pname in hyprland configs as variables
  hyprland-config-pkgs = with pkgs; [
    # TODO find better way to reconcile this with normal home.nix version so we don't reference the wrong firefox version upon changing, e.g. away from unstable in home.nix
    # + same for other apps already in home.nix
    unstable.firefox
    obsidian
    kitty
    vesktop

    imagemagick
    # system/desktop tools
    kdePackages.xwaylandvideobridge
    rofi-wayland # TODO wofi?
    waybar
    waypaper
    hyprpaper # backend for waypaper
    hyprlock
    hyprsunset
    pywal16
    hypridle
    brightnessctl
    wlogout
    playerctl
    brightnessctl
    hyprpolkitagent
    hyprsysteminfo

    nwg-look
    # kdePackages.konsole
    # kdePackages.dolphin
    decibels
    blueberry
    pavucontrol
    # gnome apps for now i guess?
    networkmanagerapplet
    nautilus
    eog
    evince
  ];
  pkgsToVars = pkgsToConv: (with builtins; (listToAttrs (map (aPkg: {
      name = builtins.replaceStrings ["-"] ["_"] "$pkg_${lib.getName aPkg}";
      value = lib.getExe aPkg;
    })
    pkgsToConv)));
in {
  home.packages = hyprland-config-pkgs ++ [];

  # TODO activation script to regenerate pywal?

  services = {
    hyprpolkitagent.enable = true;
    # notification daemon
    swaync.enable = true;
    # lockscreen service
    hypridle.enable = true;
    # bluelight filter
    hyprsunset = {
      enable = true;
      transitions = {
        sunrise = {
          calendar = "*-*-* 07:00:00";
          requests = [
            ["temperature" "6500"]
            ["gamma +10"]
          ];
        };
        sunset = {
          calendar = "*-*-* 21:00:00";
          requests = [
            ["temperature" "3200"]
            ["gamma -10"]
          ];
        };
      };
    };
    udiskie.enable = true;
  };

  # TODO make this automatic for more files with nix nonsense instead of copy-paste for more files
  xdg.configFile = {
    "hypr/configs/main.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/main.conf";
    "hypr/hyprlock.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hyprlock.conf";
    "hypr/hypridle.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hypridle.conf";
    "hypr/hyprpaper.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hyprpaper.conf";
    "rofi/config.rasi".source = mkOutOfStoreSymlink "${thisDir}/configs/rofi/config.rasi";
    "uwsm/env-hyprland".source = mkOutOfStoreSymlink "${thisDir}/configs/uwsm/env-hyprland";
    "waypaper/config.ini".source = mkOutOfStoreSymlink "${thisDir}/configs/waypaper/config.ini";
    "wlogout/layout".source = mkOutOfStoreSymlink "${thisDir}/configs/wlogout/layout";
    "wlogout/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/wlogout/style.css";
    "wal/templates/colors-hyprland.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/wal/templates/colors-hyprland.conf";
    "waybar/config.jsonc".source = mkOutOfStoreSymlink "${thisDir}/configs/waybar/config.jsonc";
    "waybar/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/waybar/style.css";
    "kitty/kitty.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/kitty/kitty.conf";
  };

  # let home-manager manage top-level hyprland.conf
  #   (but for now i put most of my actual configs in out-of-store symlink'd modules for easy reloading/iterating)
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = lib.attrsets.mergeAttrsList [
      (pkgsToVars hyprland-config-pkgs) # add in variables for installed pkgs for easy referencing in out-of-nix hyprland configs
      {
        "$wallpaper_path" = "${../../../media/wallpapers/kde-default-wallpaper.png}";
        "$reload_waybar" = "${./scripts/reload_waybar.sh}";
        source = [
          "${thisDir}/configs/hypr/main.conf"
        ];
        # repeat backspace in Xwayland apps with caps -> backspace remap
        exec-once = [
          "${lib.getExe pkgs.xorg.xset} r 66"
        ];
      }
    ];
  };

  # see https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#fixing-problems-with-themes
  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  gtk = {
    enable = true;

    theme = {
      # TODO adw-gtk3?
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    font = {
      name = "Sans";
      size = 11;
    };
  };
}
