{
  lib,
  pkgs,
  config,
  ...
}: let
  autostartPrograms = with pkgs; [vesktop telegram-desktop firefox];

  # TODO figure out what thing caused the dots in the gnome dash that indicate open apps to appear on top of the apps

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
  # TODO it'd be cool to have some custom machinery that lets me edit the settings adjacent to each extension
  extensions = with pkgs.gnomeExtensions; [
    advanced-alttab-window-switcher
    appindicator
    blur-my-shell
    clipboard-history
    focused-window-d-bus
    impatience
    steal-my-focus-window
    tiling-assistant
    quick-settings-audio-panel # volume mixer in quick settings
    custom-accent-colors # yippee :)
    user-themes
    easyeffects-preset-selector
    another-window-session-manager # auto-save session
  ];

  deckIP = "192.168.1.36";
  nautilusBookmarks = [
    "file://${config.home.homeDirectory}/Classes/Semester%2006.5 Semester 06.5"
    "file://${config.home.homeDirectory}/.var/app Flatpak Data"
    "file://${config.home.homeDirectory}/.config config"
    "file://${config.home.homeDirectory}/.local/share local share"
    # "file:///home/liz/Applications Applications"
    "file://${config.home.homeDirectory}/Documents"
    "file://${config.home.homeDirectory}/Pictures"
    "file://${config.home.homeDirectory}/Videos"
    "file://${config.home.homeDirectory}/Downloads"
    # "file://${config.home.homeDirectory}/.local/share/icons icons"
    "sftp://deck@${deckIP}/home/deck Deck Home Folder"
    "sftp://deck@${deckIP}/run/media/mmcblk0p1 Deck SD Card"
    "sftp://deck@${deckIP}/home/deck/.steam/steam/steamapps/common/Celeste Celeste Install Folder"
    "sftp://deck@${deckIP}/home/deck/.steam/steam/userdata/REDACTED/760/remote/504230/screenshots Celeste Screenshots Folder"
    "sftp://deck@${deckIP}/home/deck/.local/share/Celeste Celeste Saves Folder"
    "sftp://REDACTED@REDACTED/ifs/CS/replicated/home/REDACTED/mc_servers/fod fod mc server"
    "sftp://deck@${deckIP}/home/deck/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances Deck MC Instances"
  ];

  # gnome-related packages
  packages = with pkgs; [
    adw-gtk3
    gnome.dconf-editor
    gnome.gnome-power-manager
    gnome.gnome-themes-extra
    gnome.gnome-tweaks
  ];

  customDconf = {
    # below here is all other custom dconf entries

    # enable the extensions specified above
    "org/gnome/shell" = {
      enabled-extensions = builtins.map (extension: extension.extensionUuid) extensions;
    };

    # attempt to auto-save session
    # TODO doesn't work, find alternative
    # TODO try https://github.com/nlpsuge/gnome-shell-extension-another-window-session-manager
    # "org/gnome/gnome-session" = {
    #   auto-save-session = true;
    # };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Custom-Accent-Colors";
    };

    # custom accent colors
    "org/gnome/shell/extensions/custom-accent-colors" = {
      # options:
      # default (blue, no option set), green, yellow, orange, red, pink, purple, brown
      accent-color = "pink";
      theme-shell = true;
      theme-gtk3 = true;
      theme-flatpak = true;
    };

    # fix dark mode in gtk3 apps
    # (alternative to setting this dconf option is home-manager gtk.theme option but that conflicts with custom accent colors)
    # requires pkgs.gnome.gnome-themes-extra
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
    };

    # quick settings audio panel settings
    "org/gnome/shell/extensions/quick-settings-audio-panel" = {
      merge-panel = true;
      panel-position = "bottom";
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

    # caps lock backspace remap, plus double shift to caps lock
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["shift:both_capslock" "lv3:ralt_switch" "caps:backspace"];
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

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      edge-tiling = false;
      workspaces-only-on-primary = false;
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

    "org/gnome/shell/extensions/net/gfxmonk/impatience" = {
      speed-factor = 0.5;
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };

    "org/gnome/shell/extensions/appindicator" = {
      legacy-tray-enabled = false;
    };

    "org/gnome/shell/extensions/clipboard-history" = {
      display-mode = 0;
      history-size = 20;
      next-entry = ["<Super>period"];
      prev-entry = ["<Super>comma"];
      window-width-percentage = 20;
    };

    "org/gnome/shell/overrides" = {
      edge-tiling = false;
    };
  };
  # pathToHere = builtins.getFlakePath;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  pathToHere = "${config.home.homeDirectory}/nix/home-manager";
in
  with lib.hm.gvariant; {
    # this is a hack to allow gui editing of default apps. TODO: reconsider how to do this more elegantly
    # $XDG_CONFIG_HOME/gnome-mimeapps.list will take precedence over $XDG_CONFIG_DIRS/mimeapps.list, (see https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-1.0.html)
    # but changes can still be made to mimeapps.list in the GUI. the activation script will copy
    # these changes to home-manager's mimeapps.list, which will then symlink to the gnome-mimeapps.list file.
    xdg.configFile = {
      # TODO make the path relative to flake dir somehow (still needs to expand to absolute path for nix reasons)
      "gnome-mimeapps.list".source = mkOutOfStoreSymlink "${pathToHere}/mimeapps.list";
    };
    # TODO temporarily disabling this because it would override my mimeapps.list if I changed to new system. need 2 way sync (like with mkOutOfStoreSymlink directly to mimeapps.list)
    # imports = [
    #   ({config, ...}: {
    #     home.activation.update-mimeapps = {
    #       after = ["writeBoundary" "createXdgUserDirectories"];
    #       before = [];
    #       data = ''
    #         # copy the user's mimeapps.list to the home-manager directory
    #         if [ -f ${config.home.homeDirectory}/.config/mimeapps.list ]; then
    #           cp ${config.home.homeDirectory}/.config/mimeapps.list ${pathToHere}/mimeapps.list
    #         fi
    #       '';
    #     };
    #   })
    # ];

    home.packages = packages ++ extensions;

    # nautilus bookmarks
    gtk.gtk3.bookmarks = nautilusBookmarks;

    # jank workaround so new home.packages appear in gnome search without logging out
    # TODO figure out how to make lib.mkAfter work here
    programs.bash.profileExtra = lib.mkAfter ''
      rm -rf ${config.home.homeDirectory}/.local/share/applications/home-manager
      rm -rf ${config.home.homeDirectory}/.icons/nix-icons
      ls ~/.nix-profile/share/applications/*.desktop > ~/.cache/current_desktop_files.txt
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
