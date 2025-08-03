{
  lib,
  pkgs,
  config,
  secrets,
  inputs,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  thisDir = "${config.home.homeDirectory}/nix/home-manager/modules/hyprland-settings";
  # TODO maybe re-enable these when ready for more automatic way of generating things from this
  # additionalConfigsTargetDir = "hypr/configs/";
  # additionalConfigsSrcDir = "configs/"
  # additionalConfigs = ["main.conf"];
  gtk-theme-name = "diinki-retro-dark";

  wallpaper-path = ../../../media/wallpapers/diinki-tmp-wallpaper.png;

  theme-colors = {
    accent = "#AC82E9";
    accent-deep = "#8F56E1";
    dark = "#141216";
    lighter-dark = "#27232b";
    foreground = "#d8cab8";
    complementary-accent = "#c4e881";
    warning = "#fcb167";
    danger = "#fc4649";
    yellow = "#f3fc7b";
    green = "#c4e881";
    blue = "#7b91fc";
    cyan = "#92fcfa";
    magenta = "#fc92fc";
  };

  theme-colors-gtk-css-vars = lib.strings.concatMapStrings (colorPair: "@define-color color-${colorPair.name} ${colorPair.value};\n") (lib.attrsToList theme-colors);
  theme-colors-css-vars = ''
    :root {
      ${(lib.strings.concatMapStrings (colorPair: "--color-${colorPair.name}: ${colorPair.value};\n") (lib.attrsToList theme-colors))}
    }
  '';

  # packages to be installed + available as their pname in hyprland configs as variables
  hyprland-config-pkgs = with pkgs; [
    # TODO find better way to reconcile this with normal home.nix version so we don't reference the wrong firefox version upon changing, e.g. away from unstable in home.nix
    # + same for other apps already in home.nix
    unstable.firefox
    obsidian
    kitty
    cowsay

    # TODO: --------------------------------------------
    #   nwg-displays for GUI display management
    #   fix ly?
    #   figure out proper workflow
    #   style notification panel
    #   add more waybar widgets, e.g. for bluetooth, better wifi one, better sound one, toggling bluelight filter
    #   fix all icons, e.g. in vscode and the sound icon
    #   *****get better kindbinds for window management and stuff***** e.g. more group binds, moving windows, etc (use caps as extra modifer!!!)
    #          ideally, better keybinds for basically everything imagine to do with window movement, and have it feel natural
    #   fix btrfs-assistant
    #   style hyprlock
    #   custom/different wallpaper
    #   debug/fix wofi startup delay
    #   clipboard history gui
    #   style hyprland grouped tabs (integrate into waybar??)
    #   tweak hyprshot stuff
    #   source hyprlock wallpaper from nix
    #   set up hyprspace
    #   set up nwg-displays/other useful nwg shell stuff
    #   media widget in waybar
    #   fix text in groups overlapping with bar
    #   get hyprland cache working for git version?

    ## main desktop stuff
    # app runner
    wofi
    # status bar
    waybar
    # gui wallpaper manager TODO maybe re-add
    # waypaper
    # wallpaper backend
    hyprpaper
    # idle timeout stuff
    hypridle
    # lock screen
    hyprlock
    # bluelight filter
    hyprsunset
    # brightness control
    brightnessctl
    # gui logout thing
    wlogout
    # media controller
    playerctl
    # allow apps to get elevated permissions
    polkit_gnome
    # widgets TODO mess with eww
    # eww
    # system info gui
    hyprsysteminfo
    # gui display config manager
    nwg-displays
    # screenshots
    hyprshot

    ## other desktop apps
    # terminal
    kitty
    # GUI gtk settings editor
    nwg-look
    # audio player
    decibels
    # gnome's bluetooh configuration
    blueberry
    # audio management stuff
    pavucontrol
    # gnome gui network manager
    networkmanagerapplet
    # gnome file explorer
    nautilus
    # gnome image viewer
    eog
    # gnome document viewer
    evince
    # gui dconf editor (for use with dconf watch to add declarative dconf stuff)
    dconf-editor

    ## other tools
    imagemagick
    kdePackages.xwaylandvideobridge
    # color theme generator (currently not used, but keeping around for finding new themes)
    pywal16
    # used to create non-GTK4 themes
    themix-gui
  ];
  pkgsToVars = pkgsToConv: (with builtins; (listToAttrs (map (aPkg: {
      name = builtins.replaceStrings ["-"] ["_"] "$pkg_${lib.getName aPkg}";
      value = lib.getExe aPkg;
    })
    pkgsToConv)));
  colorsToVars = colorsAttrSet: (lib.attrsets.mapAttrs' (name: value: lib.nameValuePair ("$color_" + (builtins.replaceStrings ["-"] ["_"] name)) (lib.strings.removePrefix "#" value)) colorsAttrSet);
  hyprpkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = hyprland-config-pkgs ++ [];

  services = {
    hyprpaper = {
      enable = true;
      settings = {
        preload = ["${wallpaper-path}"];
        wallpaper = [",${wallpaper-path}"];
      };
    };
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
  # autostart polkit gnome
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      Wants = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  programs = {
    kitty = {
      enable = true;
      enableGitIntegration = true;
      shellIntegration.mode = "no-cursor";
      settings = {
        include = "${thisDir}/configs/kitty/kitty-extra.conf";
      };
    };
  };

  # TODO make this automatic for more files with nix nonsense instead of copy-paste for more files
  xdg.configFile = {
    "kitty/kitty-colors.conf".text = with theme-colors; ''
      cursor               ${accent}

      selection_background ${foreground}
      selection_foreground ${dark}

      background           ${dark}
      foreground           ${foreground}

      # TODO move this top color to the theme-colors attrset
      color0               #2b2135
      color8               ${cyan}
      color1               ${danger}
      color9               ${danger}
      color2               ${green}
      color10              ${green}
      color3               ${accent}
      color11              ${accent}
      color4               ${blue}
      color12              ${blue}
      color5               ${yellow}
      color13              ${yellow}
      color6               ${accent-deep}
      color14              ${accent-deep}
      color7               ${magenta}
      color15              ${foreground}
    '';
    "waybar/theme-colors.css".text = theme-colors-gtk-css-vars;
    "wofi/theme-colors.css".text = theme-colors-gtk-css-vars;
    "wlogout/theme-colors.css".text = theme-colors-gtk-css-vars;

    "hypr/configs/main.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/main.conf";
    "hypr/hyprlock.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hyprlock.conf";
    "hypr/hypridle.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hypridle.conf";
    "wofi/config".source = mkOutOfStoreSymlink "${thisDir}/configs/wofi/config";
    "wofi/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/wofi/style.css";
    "uwsm/env-hyprland".source = mkOutOfStoreSymlink "${thisDir}/configs/uwsm/env-hyprland";
    # TODO maybe use waypaper if i feel like it
    # "waypaper/config.ini".source = mkOutOfStoreSymlink "${thisDir}/configs/waypaper/config.ini";
    "wlogout/layout".source = mkOutOfStoreSymlink "${thisDir}/configs/wlogout/layout";
    "wlogout/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/wlogout/style.css";
    "waybar/config.jsonc".source = mkOutOfStoreSymlink "${thisDir}/configs/waybar/config.jsonc";
    "waybar/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/waybar/style.css";
    "kitty/kitty-extra.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/kitty/kitty-extra.conf"; # main kity conf is managed by home-manager
  };
  home.file.".themes/${gtk-theme-name}" = {
    source = ./configs/gtk_theme/${gtk-theme-name};
    recursive = false;
  };

  # let home-manager manage top-level hyprland.conf
  #   (but for now i put most of my actual configs in out-of-store symlink'd modules for easy reloading/iterating)
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # packages are null since we install hyprland on the NixOS side
    # package = null;
    # portalPackage = null;
    package = hyprpkg.hyprland;
    portalPackage = hyprpkg.xdg-desktop-portal-hyprland;
    plugins = [
      inputs.hyprspace.packages.${pkgs.system}.Hyprspace
    ];
    # needed for uwsm
    systemd.enable = false;
    settings = lib.attrsets.mergeAttrsList [
      (pkgsToVars hyprland-config-pkgs) # add in variables for installed pkgs for easy referencing in out-of-nix hyprland configs
      (colorsToVars theme-colors) # add in variables for colors for current theme
      {
        "$wallpaper_path" = "${wallpaper-path}";
        "$reload_waybar" = "${./scripts/reload_waybar.sh}";
        "$reload_hyprpaper" = "${./scripts/reload_hyprpaper.sh}";
        "$gtk_theme_name" = "${gtk-theme-name}";
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
      name = gtk-theme-name;
    };

    # TODO different icon theme
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    # font = {
    #   name = "Sans";
    #   size = 11;
    # };
  };
}
