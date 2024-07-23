{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  autostartPrograms = with pkgs; [vesktop telegram-desktop firefox];

  # TODO play with fonts
  # fonts.fontconfig = {
  #   enable = true;
  # };

  customKeybinds = [
    {
      name = "Gnome Console";
      command = "kgx";
      binding = "<Control><Alt>t";
    }
  ];

  # gnome extensions to install and enable
  # data structure to define settings and extensions together:
  # TODO make sure everything is using the correct datatypes (via lib.hm.gvariant)
  extensionsAndSettings = with pkgs.gnomeExtensions;
  with lib.hm.gvariant; [
    advanced-alttab-window-switcher
    blur-my-shell
    focused-window-d-bus
    steal-my-focus-window
    tiling-assistant
    easyeffects-preset-selector
    {
      package = appindicator;
      dconfPath = "appindicator"; # pname is appindicator-support so this is needed
      settings = {
        legacy-tray-enabled = false;
      };
    }
    {
      package = clipboard-history;
      settings = {
        display-mode = 0;
        history-size = 20;
        next-entry = ["<Super>period"];
        prev-entry = ["<Super>comma"];
        window-width-percentage = 20;
      };
    }
    {
      package = impatience;
      dconfPath = "net/gfxmonk/impatience";
      settings = {speed-factor = 0.5;};
    }
    {
      package = quick-settings-audio-panel; # volume mixer in quick settings
      settings = {
        merge-panel = true;
        panel-position = "bottom";
      };
    }
    {
      package = user-themes;
      dconfPath = "user-theme";
      settings = {name = "Custom-Accent-Colors";};
    }
    {
      package = pkgs.unstable.gnomeExtensions.custom-accent-colors; # yippee :)
      settings = {
        # options:
        # default (blue, no option set), green, yellow, orange, red, pink, purple, brown
        accent-color = "pink";
        theme-shell = true;
        theme-gtk3 = true;
        theme-flatpak = true;
      };
    }
    {
      package = unstable-another-window-session-manager-patched; # auto-save session
      dconfPath = "another-window-session-manager";
      settings = {
        enable-restore-previous-session = true;
        enable-autoclose-session = true;
        # custom window rules for automatic closing, needs ydotool
        close-windows-rules = ''
          '{"/home/liz/.nix-profile/share/applications/firefox.desktop":{"type":"shortcut","value":{"1":{"shortcut":"Ctrl+Q","order":1,"keyval":113,"keycode":24,"state":4},"2":{"shortcut":"Space","order":2,"keyval":32,"keycode":65,"state":0},"3":{"shortcut":"Space","order":3,"keyval":32,"keycode":65,"state":0},"4":{"shortcut":"Space","order":4,"keyval":32,"keycode":65,"state":0},"5":{"shortcut":"Space","order":5,"keyval":32,"keycode":65,"state":0},"6":{"shortcut":"Space","order":6,"keyval":32,"keycode":65,"state":0},"7":{"shortcut":"Space","order":7,"keyval":32,"keycode":65,"state":0},"8":{"shortcut":"Space","order":8,"keyval":32,"keycode":65,"state":0},"9":{"shortcut":"Space","order":9,"keyval":32,"keycode":65,"state":0},"10":{"shortcut":"Space","order":10,"keyval":32,"keycode":65,"state":0},"11":{"shortcut":"Space","order":11,"keyval":32,"keycode":65,"state":0},"12":{"shortcut":"Space","order":12,"keyval":32,"keycode":65,"state":0}},"enabled":true,"appId":"firefox.desktop","appDesktopFilePath":"/home/liz/.nix-profile/share/applications/firefox.desktop","appName":"Firefox","keyDelay":1},"/run/current-system/sw/share/applications/org.gnome.Console.desktop":{"type":"shortcut","value":{"1":{"shortcut":"Shift+Ctrl+W","order":1,"keyval":87,"keycode":25,"state":5},"2":{"shortcut":"Right","order":2,"keyval":65363,"keycode":114,"state":0},"3":{"shortcut":"Right","order":3,"keyval":65363,"keycode":114,"state":0},"4":{"shortcut":"Right","order":4,"keyval":65363,"keycode":114,"state":0},"5":{"shortcut":"Right","order":5,"keyval":65363,"keycode":114,"state":0},"6":{"shortcut":"Right","order":6,"keyval":65363,"keycode":114,"state":0},"7":{"shortcut":"Space","order":7,"keyval":32,"keycode":65,"state":0},"8":{"shortcut":"Space","order":8,"keyval":32,"keycode":65,"state":0},"9":{"shortcut":"Space","order":9,"keyval":32,"keycode":65,"state":0},"10":{"shortcut":"Space","order":10,"keyval":32,"keycode":65,"state":0}},"enabled":true,"appId":"org.gnome.Console.desktop","appDesktopFilePath":"/run/current-system/sw/share/applications/org.gnome.Console.desktop","appName":"Console","keyDelay":0}}'
        '';
        restore-previous-delay = 5;
      };
    }
  ];

  nautilusBookmarks = secrets.nautilusBookmarks;

  # gnome-related packages
  packages = with pkgs; [
    adw-gtk3
    gnome.dconf-editor
    gnome.gnome-power-manager
    gnome.gnome-themes-extra
    gnome.gnome-tweaks
  ];

  # caps lock to backspace remap
  backspaceRemapDconf = {
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["shift:both_capslock" "lv3:ralt_switch" "caps:backspace"];
    };
  };
  # fixes capslock not repeating backspace when held down in Xwayland apps
  backspaceRemapProfile = ''
    xset r 66
  '';

  extraProfile = backspaceRemapProfile + "";
  customDconf =
    backspaceRemapDconf
    // (with lib.hm.gvariant; {
      # below here is all other custom dconf entries

      "org/gnome/mutter" = {
        # enable wayland fractional scaling
        experimental-features = ["scale-monitor-framebuffer"];

        dynamic-workspaces = false;
        edge-tiling = false;
        workspaces-only-on-primary = false;
      };

      # fix dark mode in gtk3 apps
      # (alternative to setting this dconf option is home-manager gtk.theme option but that conflicts with custom accent colors)
      # requires pkgs.gnome.gnome-themes-extra
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
      };

      # set gnome background to blobs
      "org/gnome/desktop/background" = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/blobs-l.svg";
        picture-uri-dark = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/blobs-d.svg";
        primary-color = "#241f31";
        secondary-color = "#000000";
      };

      "org/gnome/desktop/interface" = {
        enable-hot-corners = false;
        show-battery-percentage = true;
      };

      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "default";
        natural-scroll = false;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        disable-while-typing = false;
        edge-scrolling-enabled = false;
        natural-scroll = false;
        speed = 0.28395061728395055;
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
      };

      "org/gnome/desktop/screensaver" = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/blobs-l.svg";
        primary-color = "#241f31";
        secondary-color = "#000000";
      };

      "org/gnome/desktop/sound" = {
        allow-volume-above-100-percent = true;
      };

      "org/gnome/desktop/wm/keybindings" = {
        maximize = [];
        move-to-workspace-1 = ["<Super>1"];
        move-to-workspace-2 = ["<Super>2"];
        move-to-workspace-3 = ["<Super>3"];
        move-to-workspace-4 = ["<Super>4"];
        switch-applications = ["<Super>Tab"];
        switch-applications-backward = ["<Shift><Super>Tab"];
        switch-to-workspace-1 = ["<Super>a"];
        switch-to-workspace-2 = ["<Super>s"];
        switch-to-workspace-3 = ["<Super>d"];
        switch-to-workspace-4 = ["<Super>f"];
        switch-windows = ["<Alt>Tab"];
        switch-windows-backward = ["<Shift><Alt>Tab"];
        toggle-fullscreen = ["<Control><Alt>Home"];
        unmaximize = [];
      };

      "org/gnome/shell/keybindings" = {
        switch-to-application-1 = [];
        switch-to-application-2 = [];
        switch-to-application-3 = [];
        switch-to-application-4 = [];
        toggle-application-view = [];
        toggle-overview = [];
        toggle-quick-settings = ["<Control><Super>s"];
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
        num-workspaces = 4;
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [];
        toggle-tiled-right = [];
      };

      "org/gnome/nautilus/compression" = {
        default-compression-format = "zip";
      };

      "org/gnome/nautilus/preferences" = {
        show-create-link = true;
      };

      "org/gnome/shell/app-switcher" = {
        current-workspace-only = true;
      };

      "org/gnome/shell/overrides" = {
        edge-tiling = false;
      };
    });

  # pathToHere = builtins.getFlakePath;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  pathToHere = "${config.home.homeDirectory}/nix/home-manager";
in {
  imports = [
    ./modules/gnome-extension-settings.nix
  ];

  # this is a hack to allow gui editing of default apps. TODO: reconsider how to do this more elegantly (maybe try continuing patching xdg-utils?)
  # TODO another option: a systemd path unit that watches for changes and then recreates the symlink
  # $XDG_CONFIG_HOME/gnome-mimeapps.list will take precedence over $XDG_CONFIG_DIRS/mimeapps.list, (see https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-1.0.html)
  # but changes can still be made to mimeapps.list in the GUI. the activation script will copy
  # these changes to home-manager's mimeapps.list, which will then symlink to the gnome-mimeapps.list file.
  xdg.configFile = {
    # TODO make the path relative to flake dir somehow (still needs to expand to absolute path for nix reasons)
    "gnome-mimeapps.list".source = mkOutOfStoreSymlink "${pathToHere}/mimeapps.list";
  };

  # calls into custom module that enables and configures settings for gnome extensions
  gnomeExtensionSettings.enable = true;
  gnomeExtensionSettings.extensionsAndSettings = extensionsAndSettings;

  home.packages = packages;

  # nautilus bookmarks
  gtk.gtk3.bookmarks = nautilusBookmarks;

  # jank workaround so new home.packages appear in gnome search without logging out
  programs.bash.profileExtra =
    extraProfile
    + ''
      rm -rf ${config.home.homeDirectory}/.local/share/applications/home-manager
      rm -rf ${config.home.homeDirectory}/.icons/nix-icons
      ls ${config.home.homeDirectory}/.nix-profile/share/applications/*.desktop > ${config.home.homeDirectory}/.cache/current_desktop_files.txt
    '';
  home.activation = {
    linkDesktopApplications = {
      after = ["writeBoundary" "createXdgUserDirectories"];
      before = [];
      data = ''
        rm -rf ${config.home.homeDirectory}/.local/share/applications/home-manager
        rm -rf ${config.home.homeDirectory}/.icons/nix-icons
        mkdir -p ${config.home.homeDirectory}/.local/share/applications/home-manager
        mkdir -p ${config.home.homeDirectory}/.icons
        ln -sf ${config.home.homeDirectory}/.nix-profile/share/icons ${config.home.homeDirectory}/.icons/nix-icons

        # Check if the cached desktop files list exists
        if [ -f ${config.home.homeDirectory}/.cache/current_desktop_files.txt ]; then
          current_files=$(cat ${config.home.homeDirectory}/.cache/current_desktop_files.txt)
        else
          current_files=""
        fi

        # Symlink new desktop entries
        for desktop_file in ${config.home.homeDirectory}/.nix-profile/share/applications/*.desktop; do
          if ! echo "$current_files" | grep -q "$(basename $desktop_file)"; then
            ln -sf "$desktop_file" ${config.home.homeDirectory}/.local/share/applications/home-manager/$(basename $desktop_file)
          fi
        done

        # Update desktop database
        ${pkgs.desktop-file-utils}/bin/update-desktop-database ${config.home.homeDirectory}/.local/share/applications
      '';
    };
  };

  # autostart programs implementation
  home.file = builtins.listToAttrs (map
    (pkg: {
      name = ".config/autostart/" + pkg.pname + ".desktop";
      value =
        if pkg ? desktopItem
        then {
          # Application has a desktopItem entry.
          # Assume that it was made with makeDesktopEntry, which exposes a
          # text attribute with the contents of the .desktop file
          text = pkg.desktopItem.text;
        }
        else {
          # Application does *not* have a desktopItem entry. Try to find a
          # matching .desktop name in /share/applications
          source = with builtins; let
            appsPath = "${pkg}/share/applications";
            # function to filter out subdirs of /share/applications
            filterFiles = dirContents: lib.attrsets.filterAttrs (_: fileType: elem fileType ["regular" "symlink"]) dirContents;
          in (
            # if there's a desktop file by the app's pname, use that
            if (pathExists "${appsPath}/${pkg.pname}.desktop")
            then "${appsPath}/${pkg.pname}.desktop"
            # if there's not, find the first desktop file in the app's directory and assume that's good enough
            else
              (
                if pathExists "${appsPath}"
                then "${appsPath}/${head (attrNames (filterFiles (readDir "${appsPath}")))}"
                else throw "no desktop file for app ${pkg.pname}"
              )
          );
        };
    })
    autostartPrograms);
  # this first part is the implementation of custom keybinds
  dconf.settings =
    lib.mkMerge
    [
      (let
        inherit (builtins) length head tail listToAttrs genList;
        range = a: b:
          if a < b
          then [a] ++ range (a + 1) b
          else [];
        globalPath = "org/gnome/settings-daemon/plugins/media-keys";
        path = "${globalPath}/custom-keybinding";
        mkPath = id: "${globalPath}/custom${toString id}";
        isEmpty = list: length list == 0;
        mkSettings = settings: let
          checkSettings = {
            name,
            command,
            binding,
          } @ this:
            this;
          aux = i: list:
            if isEmpty list
            then []
            else let
              hd = head list;
              tl = tail list;
              name = mkPath i;
            in
              aux (i + 1) tl
              ++ [
                {
                  name = mkPath i;
                  value = checkSettings hd;
                }
              ];
          settingsList = aux 0 settings;
        in
          listToAttrs (settingsList
            ++ [
              {
                name = globalPath;
                value = {
                  custom-keybindings = genList (i: "/${mkPath i}/") (length settingsList);
                };
              }
            ]);
      in
        mkSettings customKeybinds)
      # add custom dconf declared above
      customDconf
    ];
}
