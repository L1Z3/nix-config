{
  lib,
  pkgs,
  config,
  ...
}: {
  # TODO list of items to get Plasma to a place where I like it:
  #  - tweak workflow to be slightly more like GNOME (or just cope): e.g., Meta somehow opens overview + type to search
  #  - change default touchpad gestures (they exist, just hard-coded): either with kwin patch, or with [insert link]
  #  - different screen orientation when docked vs not
  #  - show taskbar in overview menu
  #  - finish adding old gnome bookmarks (~/.config/gtk-3.0/bookmarks) to dolphin

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # my custom kde overrides
  # TODO fix
  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (kdeFinal: kdePrev: {
        # rebind switch desktop from Meta + Alt + Scroll (reversed) to Meta + Scroll (not reversed)
        # (because for ~some reason~ the KDE devs decided to ~hard code~ this...)
        kwin = kdePrev.kwin.overrideAttrs (prevPkgAttrs: {
          patches = (prevPkgAttrs.patches or []) ++ [./rebind-hardcoded-virtual-desktop-shortcuts.patch];
        });
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
}
