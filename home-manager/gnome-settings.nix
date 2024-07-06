{
  lib,
  pkgs,
  config,
  ...
}: let
  autostartPrograms = with pkgs; [vesktop telegram-desktop firefox];
  deckIP = "192.168.1.36";
  nautilusBookmarks = [
    "file:///home/liz/Classes/Semester%2006.5 Semester 06.5"
    "file:///home/liz/.var/app Flatpak Data"
    "file:///home/liz/Applications Applications"
    "file:///home/liz/Documents"
    "file:///home/liz/Pictures"
    "file:///home/liz/Videos"
    "file:///home/liz/Downloads"
    "file:///home/liz/.local/share/icons icons"
    "sftp://deck@${deckIP}/home/deck Deck Home Folder"
    "sftp://deck@${deckIP}/run/media/mmcblk0p1 Deck SD Card"
    "sftp://deck@${deckIP}/home/deck/.steam/steam/steamapps/common/Celeste Celeste Install Folder"
    "sftp://deck@${deckIP}/home/deck/.steam/steam/userdata/REDACTED/760/remote/504230/screenshots Celeste Screenshots Folder"
    "sftp://deck@${deckIP}/home/deck/.local/share/Celeste Celeste Saves Folder"
    "sftp://REDACTED@REDACTED/ifs/CS/replicated/home/REDACTED/mc_servers/fod fod mc server"
    "sftp://deck@${deckIP}/home/deck/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances Deck MC Instances"
  ];
  customKeybinds = [
    {
      name = "Gnome Console";
      command = "kgx";
      binding = "<Control><Alt>t";
    }
  ];
in
  # nautilus bookmarks
  with lib.hm.gvariant; {
    gtk.gtk3.bookmarks = nautilusBookmarks;

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
            # matching .desktop name in /share/apaplications
            source = pkg + "/share/applications/" + pkg.pname + ".desktop";
          };
      })
      autostartPrograms);

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
        {
          # below here is all other custom dconf entries

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

          # fix dark mode in gtk3 apps
          # "org/gnome/desktop/interface" = {
          #   color-scheme = "prefer-dark";
          #   gtk-theme = "adw-gtk3-dark";
          # };

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
            picture-uri = "file:///usr/share/backgrounds/gnome/blobs-l.svg";
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

          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = ["force-show-osk@bruh.ltd" "focus-my-window@varianto25.com" "noannoyance@sindex.com" "background-logo@fedorahosted.org" "openweather-extension@jenslody.de" "emoji-selector@maestroschan.fr" "noannoyance@daase.net" "drive-menu@gnome-shell-extensions.gcampax.github.com" "improvedosk@nick-shmyrev.dev" "auto-move-windows@gnome-shell-extensions.gcampax.github.com" "smart-auto-move@khimaros.com" "clipboard-history@alexsaveau.dev" "blur-my-shell@aunetx" "focused-window-dbus@flexagoon.com" "tiling-assistant@leleat-on-github" "window-calls-extended@hseliger.eu" "appindicatorsupport@rgcjonas.gmail.com" "steal-my-focus-window@steal-my-focus-window" "advanced-alt-tab@G-dH.github.com" "impatience@gfxmonk.net"];
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

          "org/gnome/shell/keybindings" = {
            switch-to-application-1 = [];
            switch-to-application-2 = [];
            switch-to-application-3 = [];
            switch-to-application-4 = [];
            toggle-application-view = [];
            toggle-overview = [];
            toggle-quick-settings = [];
          };

          "org/gnome/shell/overrides" = {
            edge-tiling = false;
          };
        }
      ];
  }
