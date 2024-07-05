# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{lib, ...}:
with lib.hm.gvariant; {
  dconf.settings = {
    # "org/gnome/desktop/background" = {
    #   color-shading-type = "solid";
    #   picture-options = "zoom";
    #   picture-uri = "file:///usr/share/backgrounds/gnome/blobs-l.svg";
    #   picture-uri-dark = "file:///usr/share/backgrounds/gnome/blobs-d.svg";
    #   primary-color = "#241f31";
    #   secondary-color = "#000000";
    # };

    # fix dark mode in gtk3 apps
    # "org/gnome/desktop/interface" = {
    #   color-scheme = "prefer-dark";
    #   gtk-theme = "adw-gtk3-dark";
    # };

    # caps lock backspace remap, plus double shift to caps lock
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["shift:both_capslock" "lv3:ralt_switch" "caps:backspace"];
    };

    # "org/gnome/desktop/interface" = {
    #   clock-format = "24h";
    #   clock-show-date = true;
    #   clock-show-weekday = true;
    #   color-scheme = "prefer-dark";
    #   document-font-name = "Roboto 11";
    #   enable-hot-corners = false;
    #   font-antialiasing = "grayscale";
    #   font-hinting = "slight";
    #   font-name = "Roboto 11";
    #   gtk-theme = "Adwaita-dark";
    #   icon-theme = "Adwaita";
    #   monospace-font-name = "Monospace 10";
    #   show-battery-percentage = true;
    #   toolkit-accessibility = false;
    # };

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
  };
}
