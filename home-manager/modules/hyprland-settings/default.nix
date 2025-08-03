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
    #   nwg-displays for GUI display management
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
    #   style group stuff in hyprland
    #   get hyprland cache working for git version?
    #   determine if package version mismatch between, e.g. hyprshot depending on hyprland 0.5.1 and hyprspace forcing it at 0.5.0 is a problem
    #   theme tui greet better
    #   theme firefox/tree style tab
    #   FIGURE OUT PROPER SESSION MANAGEMENT!!!
    #   KEEP ENABLING/FIXING CATPPUCCIN FOR EVERYTHING

    ## main desktop stuff
    # app runner
    wofi
    # status bar
    waybar
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
    # gui logout thing
    wlogout
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

    # cursor theme
    cursor-theme-package
  ];
  pkgsToVars = pkgsToConv: (with builtins; (listToAttrs (map (aPkg: {
      name = builtins.replaceStrings ["-"] ["_"] "$pkg_${lib.getName aPkg}";
      value = lib.getExe aPkg;
    })
    pkgsToConv)));
  colorsToVars = colorsAttrSet: (lib.attrsets.mapAttrs' (name: value: lib.nameValuePair ("$color_" + (builtins.replaceStrings ["-"] ["_"] name)) (lib.strings.removePrefix "#" value)) colorsAttrSet);
  hyprpkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  pkgs-hypr = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
    waybar.enable = true;
    waybar.mode = "createLink";
    # for some reason, this is causing the hm switch to get stuck forever...
    # NOTE: currently if flavor != mocha or accent != blue, the build will freeze.
    #       see https://github.com/NixOS/nixpkgs/issues/426952
    gtk.icon.enable = true;
    gtk.icon.accent = "blue";
  };

  services = {
    hyprpaper = {
      enable = true;
      package = pkgs-hypr.hyprpaper;
      settings = {
        preload = ["${wallpaper-path}"];
        wallpaper = [",${wallpaper-path}"];
      };
    };
    # notification daemon
    swaync.enable = true;
    # lockscreen service
    hypridle.enable = true;
    hypridle.package = pkgs-hypr.hypridle;
    # bluelight filter
    # TODO reenable
    # hyprsunset = {
    #   enable = true;
    #   transitions = {
    #     sunrise = {
    #       calendar = "*-*-* 07:00:00";
    #       requests = [
    #         ["temperature" "6500"]
    #         ["gamma +10"]
    #       ];
    #     };
    #     sunset = {
    #       calendar = "*-*-* 21:00:00";
    #       requests = [
    #         ["temperature" "3200"]
    #         ["gamma -10"]
    #       ];
    #     };
    #   };
    # };
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
    waybar.enable = true;
  };

  # TODO make this automatic for more files with nix nonsense instead of copy-paste for more files
  xdg.configFile = {
    # "kitty/kitty-colors.conf".text = with theme-colors; ''
    #   cursor               ${accent}

    #   selection_background ${foreground}
    #   selection_foreground ${dark}

    #   background           ${dark}
    #   foreground           ${foreground}

    #   # TODO move this top color to the theme-colors attrset
    #   color0               #2b2135
    #   color8               ${cyan}
    #   color1               ${danger}
    #   color9               ${danger}
    #   color2               ${green}
    #   color10              ${green}
    #   color3               ${accent}
    #   color11              ${accent}
    #   color4               ${blue}
    #   color12              ${blue}
    #   color5               ${yellow}
    #   color13              ${yellow}
    #   color6               ${accent-deep}
    #   color14              ${accent-deep}
    #   color7               ${magenta}
    #   color15              ${foreground}
    # '';
    "waybar/theme-colors.css".text = theme-colors-gtk-css-vars;
    "wofi/theme-colors.css".text = theme-colors-gtk-css-vars;
    "wlogout/theme-colors.css".text = theme-colors-gtk-css-vars;

    "hypr/configs/main.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/main.conf";
    "hypr/hyprlock.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hyprlock.conf";
    "hypr/hypridle.conf".source = mkOutOfStoreSymlink "${thisDir}/configs/hypr/hypridle.conf";
    "wofi/config".source = mkOutOfStoreSymlink "${thisDir}/configs/wofi/config";
    "wofi/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/wofi/style.css";
    "wlogout/layout".source = mkOutOfStoreSymlink "${thisDir}/configs/wlogout/layout";
    "wlogout/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/wlogout/style.css";
    "waybar/config.jsonc".source = mkOutOfStoreSymlink "${thisDir}/configs/waybar/config.jsonc";
    "waybar/style.css".source = mkOutOfStoreSymlink "${thisDir}/configs/waybar/style.css";
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
}
