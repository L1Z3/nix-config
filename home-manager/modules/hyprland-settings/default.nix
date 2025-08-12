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

  # a fun little secret: i don't how how determine what the theme name of a package is in a normal way...
  #   so, instead, i just run `nix-tree ~/.nix-profile` after installing the theme with hm, then search with /,
  #   then find the path at the bottom, then navigate to that path in the nix store and look at what the folder name is.
  gtk-theme-name = "catppuccin-mocha-mauve-standard";
  cursor-theme-name = "catppuccin-mocha-mauve-cursors";
  cursor-theme-package = pkgs.catppuccin-cursors.mochaMauve;

  wallpaper-path = ../../../media/wallpapers/laundry.png;

  theme-colors = {
    accent = "#cba6f7";
    accent-deep = "#cba6f7";
    dark = "#11111b";
    lighter-dark = "#181825";
    foreground = "#cdd6f4";
    complementary-accent = "#74c7ec";
    warning = "#fab387";
    danger = "#f38ba8";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    blue = "#89b4fa";
    cyan = "#89dceb";
    magenta = "#cba6f7";
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
    #   nwg-displays for GUI display management (also shortcut for it in hyprpanel dashboardmenu)
    #   FIGURE OUT PROPER SESSION MANAGEMENT!!! (maybe just better autostart)
    #   make colors better for hyprland
    #   master layout binds?
    #   make linked monitor switch bind better
    #      specifically, have different a different submap that imports all normal binds (source) and then unbinds workspace switch ones, replacing them with the linked ones
    #          could be a script that unbinds the workspace switch binds and then rebinds them to the linked ones
    #   fix hyprsunset schedule
    #   get keyring figured out... don't want to type in ssh passphrase all the time
    #   use libinput gestures to make zoom work with touchpad
    #   keybind for pin

    ## main desktop stuff
    # app runner
    rofi-wayland
    # wallpaper backend
    pkgs-hypr.hyprpaper
    # idle timeout stuff
    pkgs-hypr.hypridle
    # lock screen
    pkgs-hypr.hyprlock
    # bluelight filter
    pkgs-hypr.hyprsunset
    # brightness control
    brightnessctl
    # media controller
    playerctl
    # allow apps to get elevated permissions
    polkit_gnome
    # widgets TODO mess with eww
    # eww
    # system info gui
    pkgs-hypr.hyprsysteminfo
    # gui display config manager
    nwg-displays
    # screenshots
    pkgs-hypr.hyprshot

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
    networkmanager_dmenu
    # gnome file explorer
    nautilus
    file-roller
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

    # cursor theme
    cursor-theme-package

    # clipboard
    wl-clip-persist
    wl-clipboard

    # json parsing
    jq

    # audio stuff
    libcanberra-gtk3

    hyprls

    rofimoji
  ];
  pkgsToVars = pkgsToConv: (with builtins; (listToAttrs (map (aPkg: {
      name = builtins.replaceStrings ["-"] ["_"] "$pkg_${lib.getName aPkg}";
      value = lib.getExe aPkg;
    })
    pkgsToConv)));
  colorsToVars = colorsAttrSet: (lib.attrsets.mapAttrs' (name: value: lib.nameValuePair ("$color_" + (builtins.replaceStrings ["-"] ["_"] name)) (lib.strings.removePrefix "#" value)) colorsAttrSet);
  # pkgs-hypr = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  pkgs-hypr = pkgs;
in {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  home.packages = hyprland-config-pkgs ++ [];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
    # TODO re-enable this. it's disabled to prevent conflicts right now
    vscode.profiles.default.enable = false;
    gtk.icon.enable = true;
    hyprlock.useDefaultConfig = false;
    kvantum.enable = true;
  };

  services = {
    # clipboard history
    cliphist.enable = true;
    hyprpaper = {
      enable = true;
      package = pkgs-hypr.hyprpaper;
      settings = {
        preload = ["${wallpaper-path}"];
        wallpaper = [",${wallpaper-path}"];
      };
    };
    # lockscreen service
    hypridle.enable = true;
    hypridle.package = pkgs-hypr.hypridle;
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
    # only down here as well as in home.packages so that catppuccin nix can see it
    # waybar.enable = true;
    hyprpanel.enable = true;
    # i want to be able to use the GUI for managing settings, and so we don't want any settings being generated
    hyprpanel.settings = lib.mkForce {};
    hyprlock = {
      enable = true;
      package = pkgs-hypr.hyprlock;
      settings = {
        "$wallpaper" = "${wallpaper-path}";
        source = lib.mkAfter ["${config.home.homeDirectory}/.config/hypr/hyprlock-extra.conf"];
      };
    };
  };

  # TODO make this automatic for more files with nix nonsense instead of copy-paste for more files
  xdg.configFile = {
    "networkmanager-dmenu/config.ini".source = mkOutOfStoreSymlink "${thisDir}/configs/networkmanager-dmenu/config.ini";
    "hypr/configs/main.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/main.conf";
    "hypr/configs/special-workspaces.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/special-workspaces.conf";
    "hypr/hyprlock-extra.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hyprlock-extra.conf";
    "hypr/hypridle.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hypridle.conf";
    "hypr/hyprsunset.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hyprsunset.conf";
    "hyprpanel/config.json".source = mkOutOfStoreSymlink "${thisDir}/configs/hyprpanel/config.json";
    "hyprpanel/modules.json".source = mkOutOfStoreSymlink "${thisDir}/configs/hyprpanel/modules.json";
    "rofi/config.rasi".source = mkOutOfStoreSymlink "${thisDir}/configs/rofi/config.rasi";
    "rofi/catppuccin-lavrent-mocha.rasi".source = mkOutOfStoreSymlink "${thisDir}/configs/rofi/catppuccin-lavrent-mocha.rasi";
    "kitty/kitty-extra.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/kitty/kitty-extra.conf"; # main kity conf is managed by home-manager

    # passes through hm env vars to uwsm
    "uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
  };
  # home.file.".themes/${gtk-theme-name}" = {
  #   source = ./configs/gtk_theme/${gtk-theme-name};
  #   recursive = false;
  # };

  # let home-manager manage top-level hyprland.conf
  #   (but for now i put most of my actual configs in out-of-store symlink'd modules for easy reloading/iterating)
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # packages are null since we install hyprland on the NixOS side
    package = null;
    portalPackage = null;
    # also needed since we install hyprland on the nixos side
    systemd.variables = ["--all"];
    # package = hyprpkg.hyprland;
    # portalPackage = hyprpkg.xdg-desktop-portal-hyprland;
    plugins = with pkgs.hyprlandPlugins; [
      # hyprspace
      hyprexpo
      hyprsplit
      hyprgrass
      hypr-dynamic-cursors
      # hyprwinwrap # reenable if i want wallpaper engine
    ];
    # needed for uwsm
    systemd.enable = false;
    settings = lib.attrsets.mergeAttrsList [
      (pkgsToVars hyprland-config-pkgs) # add in variables for installed pkgs for easy referencing in out-of-nix hyprland configs
      (colorsToVars theme-colors) # add in variables for colors for current theme
      {
        "$wallpaper_path" = "${wallpaper-path}";
        "$reload_hyprpanel" = "${mkOutOfStoreSymlink "${thisDir}/scripts/reload_hyprpanel.sh"}";
        "$reload_hyprpaper" = "${mkOutOfStoreSymlink "${thisDir}/scripts/reload_hyprpaper.sh"}";
        "$linked_monitor_switch" = "${mkOutOfStoreSymlink "${thisDir}/scripts/linked_monitor_switch.sh"}";
        "$open_last_screenshot" = "${mkOutOfStoreSymlink "${thisDir}/scripts/open-last-screenshot.sh"}";
        "$pkg_window_search" = "${mkOutOfStoreSymlink "${thisDir}/scripts/window-search.py"}";
        "$swap_monitor_positions" = "${mkOutOfStoreSymlink "${thisDir}/scripts/swap-monitor-positions.sh"}";
        "$set_sink_volume" = "${mkOutOfStoreSymlink "${thisDir}/scripts/set-sink-volume-by-substring.sh"}";
        "$gtk_theme_name" = "${gtk-theme-name}";
        "$cursor_theme_name" = "${cursor-theme-name}";
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
    x11.enable = true;
    hyprcursor.enable = true;
    package = cursor-theme-package;
    name = cursor-theme-name;
    size = 24;
  };

  gtk = {
    enable = true;
    # if the normal gtk theme stops working (it's no longer supported), i can try magnetic-catppuccin-gtk
    theme = {
      name = "${gtk-theme-name}";
      package = pkgs.catppuccin-gtk.override {
        accents = ["mauve"];
        variant = "mocha";
      };
    };

    # font = {
    #   name = "Sans";
    #   size = 11;
    # };
  };

  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
}
