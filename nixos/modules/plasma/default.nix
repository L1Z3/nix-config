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
  #     - debug with method discussed here? https://bugs.kde.org/show_bug.cgi?id=490358#c8
  #  - once my configs are stable, migrate to plasma-manager
  #  - different screen orientation when docked vs not
  #     - seems hard; should make issue and/or just work around it with udev/kscript nonsense/just copew with autorotate
  #     - make issue about not being able to make orientation tied to setup
  #  - finish adding old gnome bookmarks (~/.config/gtk-3.0/bookmarks) to dolphin
  #  - show taskbar in overview menu (doesn't seem possible)
  #  - fix pen?
  #  - fix emojis????????

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # apparently these lines were needed for spectacle to allow copying to clipboard when the window isn't open??? cool i guess (https://discourse.nixos.org/t/spectacle-errors-plasma6-wayland/50753/4, https://github.com/drupol/nixos-x260/blob/d18965e30e3baed5ff141b206dc995add2ce6cfe/modules/system/desktop/default.nix#L19)
  xdg.portal.enable = true;
  xdg.portal.config.common.default = "kde";
  xdg.portal.extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];

  # my custom kde overrides
  nixpkgs.overlays = [
    (final: prev: {
      # try unstable again
      kdePackages = prev.kdePackages.overrideScope (kdeFinal: kdePrev: {
        kwin = kdePrev.kwin.overrideAttrs (prevPkgAttrs: {
          patches =
            (prevPkgAttrs.patches or [])
            ++ [
              # for ~some reason~ the KDE devs decided to ~hard code~ these controls
              # this patch modifies virtual desktop controls in Plasma to act more like GNOME:
              #   - rebind switch desktop from `Meta + Alt + Scroll` to `Meta + Scroll` and reverses the direction
              #   - reverse direction of touchpad left/right switch virtual desktop gestures
              #   - removes touchpad up/down switch virtual desktop gestures
              #   - makes the touchpad up/down overview gestures 3 finger instead of 4 finger
              #   - reverses the direction of the touchpad up/down overview gestures
              ./rebind-hardcoded-virtual-desktop-shortcuts.patch
              # https://invent.kde.org/plasma/kwin/-/merge_requests/5553
              ./scroll-in-overview.patch
            ];
        });

        # hack to workaround https://bugs.kde.org/show_bug.cgi?id=488139
        kscreen = kdePrev.kscreen.overrideAttrs (prevPkgAttrs: {
          patches = (prevPkgAttrs.patches or []) ++ [./force-enable-autorotate-ui.patch];
        });

        # i'm gonna go insane, i think my entire goddamn desktop environment is slow af just because XDG_DATA_DIRS is massive and because
        # KDE spends countless CPU cycles searching for a `colors` directory for the theme in every single XDG_DATA_DIRS entry,
        # so here is a jank patch that removes the code that does that :)
        # (i WISH i could just make XDG_DATA_DIRS not massive but i think that's due to nix wrapping KDE programs in a way i don't understand
        # so maybe this fix will work instead :))
        ksvg = kdePrev.ksvg.overrideAttrs (prevPkgAttrs: {
          patches = (prevPkgAttrs.patches or []) ++ [./jank-ksvg-xdg-data-dirs-lag-fix.patch];
        });

        # patch to fix https://bugs.kde.org/show_bug.cgi?id=485927 (from https://bugs.kde.org/show_bug.cgi?id=485927#c10)
        # TODO won't work right now, getting weird mismatched dependencies error
        # qtbase = kdePrev.qtbase.overrideAttrs (prevPkgAttrs: {
        #   patches = (prevPkgAttrs.patches or []) ++ [./fix-60hz-cap-overview-anim.patch];
        # });
      });
    })
  ];

  # attempted fix that seems to mitigate overview effect stutters a bit
  # systemd.services.fix-plasma-stutters = {
  #   description = "Sets intel gpu min frequency";
  #   path = [pkgs.intel-gpu-tools];
  #   script = "intel_gpu_frequency -c min=600";
  #   wantedBy = ["graphical.target"];
  # };

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

  environment.sessionVariables = {
    # fix lag on intel iris xe graphics?? https://bugs.kde.org/show_bug.cgi?id=488860
    # KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "1";
    # proposed fix for overview lag i saw somewhere
    # KWIN_DRM_OVERRIDE_SAFETY_MARGIN = "6000";
    # KWIN_LOG_PERFORMANCE_DATA = 1;
  };

  # https://wiki.nixos.org/wiki/SSH_public_key_authentication#KDE
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
  };

  environment.variables = {
    SSH_ASKPASS_REQUIRE = "prefer"; # potentially need SSH_ASKPASS_REQUIRE="force" for first-time remember password?
  };
}
