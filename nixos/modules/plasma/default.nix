{
  lib,
  pkgs,
  config,
  ...
}: {
  # TODO list of items to get Plasma to a place where I like it:
  #  - make plasma look nicer
  #  - make plasma less sluggish? like the overview effect is really slow...
  #     - related: https://bugs.kde.org/show_bug.cgi?id=479250
  #  - once my configs are stable, migrate to plasma-manager
  #  - different screen orientation when docked vs not
  #     - seems hard; should make issue and/or just work around it with udev/kscript nonsense/just copew with autorotate
  #  - finish adding old gnome bookmarks (~/.config/gtk-3.0/bookmarks) to dolphin
  #  - show taskbar in overview menu (doesn't seem possible)

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # my custom kde overrides
  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (kdeFinal: kdePrev: {
        # for ~some reason~ the KDE devs decided to ~hard code~ these controls
        # this patch modifies virtual desktop controls in Plasma to act more like GNOME:
        #   - rebind switch desktop from `Meta + Alt + Scroll` to `Meta + Scroll` and reverses the direction
        #   - reverse direction of touchpad left/right switch virtual desktop gestures
        #   - removes touchpad up/down switch virtual desktop gestures
        #   - makes the touchpad up/down overview gestures 3 finger instead of 4 finger
        #   - reverses the direction of the touchpad up/down overview gestures
        kwin = kdePrev.kwin.overrideAttrs (prevPkgAttrs: {
          patches = (prevPkgAttrs.patches or []) ++ [./rebind-hardcoded-virtual-desktop-shortcuts.patch];
        });

        # hack to workaround https://bugs.kde.org/show_bug.cgi?id=488139
        kscreen = kdePrev.kscreen.overrideAttrs (prevPkgAttrs: {
          patches = (prevPkgAttrs.patches or []) ++ [./force-enable-autorotate-ui.patch];
        });

        # patch to fix https://bugs.kde.org/show_bug.cgi?id=485927 (from https://bugs.kde.org/show_bug.cgi?id=485927#c10)
        # TODO won't work right now, getting weird mismatched dependencies error
        # qtbase = kdePrev.qtbase.overrideAttrs (prevPkgAttrs: {
        #   patches = (prevPkgAttrs.patches or []) ++ [./fix-60hz-cap-overview-anim.patch];
        # });
      });
    })
  ];

  environment.systemPackages =
    (with pkgs.kdePackages; [
      plasma-thunderbolt
      sddm-kcm
      qt6ct
      kde-gtk-config
    ])
    ++ (with pkgs; [
      ]);

  # hack to automatically transfer plasma configs to sddm (https://wiki.archlinux.org/title/SDDM#Match_Plasma_display_configuration)
  systemd.tmpfiles.rules = [
    "r /var/lib/sddm/.config/kwinoutputconfig.json"
    "C+ /var/lib/sddm/.config/kwinoutputconfig.json 0644 sddm sddm - /home/liz/.config/kwinoutputconfig.json"
    "r /var/lib/sddm/.config/kcminputrc"
    "C+ /var/lib/sddm/.config/kcminputrc 0644 sddm sddm - /home/liz/.config/kcminputrc"
  ];

  # fix lag on intel iris xe graphics https://bugs.kde.org/show_bug.cgi?id=488860
  environment.sessionVariables = {
    KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "1";
  };
}
