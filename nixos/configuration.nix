# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    ./modules/nvidia-egpu.nix
    ./modules/xbox.controller-bluetooth-fix.nix

    # enable gnome
    # ./modules/gnome.nix

    # enable kde plasma 6
    # ./modules/plasma

    # enable hyprland
    ./modules/hyprland

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  # Bootloader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/vda";
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 50; # idk if this is needed, but just in case
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.grub.useOSProber = true;

  # summary of kernel version constraints:
  # speakers only work on 6.9+
  # LTS 6.6: suspend/resume works, no kernel memory leaks
  # 6.12: kernel memory leaks
  # 6.13-6.13.5: FUSE/Flatpak issues
  # 6.13.6 seems good? i think the memory leaks i was having are fixed
  # unstable pkgs to fix a nvidia driver issue
  # boot.kernelPackages = pkgs.unstable.linuxPackages_xanmod_stable;
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  # fix for unable to wake from suspend during some FUSE or BTRFS operations
  systemd.services."systemd-suspend".serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";

  # temporarily enable kmemleak to debug kernel memory leaks
  # boot.kernelPatches = [
  #   {
  #     name = "kmemleak-config";
  #     patch = null;
  #     extraConfig = ''
  #       DEBUG_KMEMLEAK y
  #       DEBUG_FS y
  #       SYSFS y
  #     '';
  #   }
  # ];
  # boot.kernelParams = [
  #   "kmemleak=on"
  # ];

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # make amazon fire stick think this laptop is a pair of headphones
  # hardware.bluetooth.settings = {
  #   General = {
  #     Class = "0x002c0414";
  #   };
  # };
  # services.blueman.enable = true;

  # enable experimental bluetooth le/lc3 codec support
  # FUTURE: maybe enable for Bluetooth LE/LC3 when more stable
  # hardware.bluetooth = {
  #   enable = true;
  #   powerOnBoot = true;
  #   settings = {
  #     General = {
  #       ControllerMode = "le";
  #       Experimental = true;
  #       KernelExperimental = true;
  #     };
  #   };
  # };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # automatic screen rotation
  hardware.sensor.iio.enable = true;

  # TODO try hyprland sometime

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [gutenprint canon-cups-ufr2 cups-filters];
  };
  # enable network printer discovery
  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  #   openFirewall = true;
  # };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;

    # need to disabled bap_sink for WF-1000XM5 to connect with LC3 codec
    # FUTURE: maybe enable for Bluetooth LE/LC3 when more stable
    # wireplumber.extraConfig.fixWF1000XM5 = {
    #   "monitor.bluez.properties" = {
    #     "bluez5.roles" = [
    #       "a2dp_sink"
    #       "a2dp_source"
    #       # "bap_sink" # https://github.com/bluez/bluez/issues/793#issuecomment-2050379540 WF-1000XM5 LC3 doesn't support mic
    #       "bap_source"
    #       "hsp_hs"
    #       /*
    #       "hsp_ag" # disabled by default
    #       */
    #       "hfp_hf"
    #       "hfp_ag"
    #     ];
    #   };
    # };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.system-modifications
      outputs.overlays.unstable-packages

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # enable hardware encoding for OBS/Davinci Resolve
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime # for davinci resolve
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };

  # environment.sessionVariables = {LIBVA_DRIVER_NAME = "iHD";}; # Force intel-media-driver

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
      # auto-optimize to reduce disk usage
      auto-optimise-store = true;
      # allow cachix with nonroot
      trusted-users = ["root" "@wheel"];
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    # automatic garbage collection for system generations
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 7d";
    #   persistent = true;
    # };
  };

  networking.hostName = "envy";

  users.users = {
    liz = {
      isNormalUser = true;
      # to allow gdm to access $HOME/.face
      # TODO should this be changed somehow to restrict access to only gdm?
      homeMode = "711";
      description = "Elizabeth Jones";
      # Be sure to change the default password (using passwd) after rebooting on fresh install!
      initialPassword = "correcthorsebatterystaple";
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      # Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = ["users" "liz" "networkmanager" "wheel" "libvirtd" "qemu-libvirtd" "kvm" "docker"];
    };
  };
  # in addition to default group of users=100, add liz=1000 since i have lots of files with gid=1000
  users.groups = {
    liz = {
      gid = 1000;
    };
  };

  programs = {
    # can't enable steam in home-manager, so system-wide instead
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      # dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      # this is just a note for me: currently in the steam families beta, web view (store, community, etc) don't work
      #    unless i disable GPU acceleration in web views in the interface settings.

      # TODO gamescopesession is broken for me, try to figure out why
      # gamescopeSession.enable = true;
      # protontricks.enable = true; # only in unstable, TODO enable in future update
      # extra packages that seem to make gamescope work in steam
      # extraPackages = with pkgs; [
      #   xorg.libXcursor
      #   xorg.libXi
      #   xorg.libXinerama
      #   xorg.libXScrnSaver
      #   libpng
      #   libpulseaudio
      #   libvorbis
      #   stdenv.cc.cc.lib
      #   libkrb5
      #   keyutils
      # ];
    };
    # gamescope.enable = true;
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    # TODO reenable when actually needed so i can figure out how to use properly
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libz
        zlib
        fuse
        fuse3
        icu
        nss
        expat
        xorg.libxcb
        xorg.libX11
        xorg.libXcursor
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
        libGL
        freetype
        fontconfig
        alsa-lib
        e2fsprogs
        libGL
        libgcc.lib
        libgpg-error
        libgcc
        # zlib

        # libraries so jetbrains IDEs are happy (from https://nixos.wiki/wiki/Jetbrains_Tools)
        SDL
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        SDL_image
        SDL_mixer
        SDL_ttf
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        bzip2
        cairo
        cups
        curlWithGnuTls
        dbus
        dbus-glib
        desktop-file-utils
        e2fsprogs
        expat
        flac
        fontconfig
        freeglut
        freetype
        fribidi
        fuse
        fuse3
        gdk-pixbuf
        glew110
        glib
        gmp
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-ugly
        gst_all_1.gstreamer
        gtk2
        harfbuzz
        icu
        keyutils.lib
        libGL
        libGLU
        libappindicator-gtk2
        libcaca
        libcanberra
        libcap
        libclang.lib
        libdbusmenu
        libdrm
        libgcrypt
        libgpg-error
        libidn
        libjack2
        libjpeg
        libmikmod
        libogg
        libpng12
        libpulseaudio
        librsvg
        libsamplerate
        libthai
        libtheora
        libtiff
        libudev0-shim
        libusb1
        libuuid
        libvdpau
        libvorbis
        libvpx
        libxcrypt-legacy
        libxkbcommon
        libxml2
        mesa
        nspr
        nss
        openssl
        p11-kit
        pango
        pixman
        python3
        speex
        stdenv.cc.cc
        tbb
        udev
        vulkan-loader
        wayland
        xorg.libICE
        xorg.libSM
        xorg.libX11
        xorg.libXScrnSaver
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXft
        xorg.libXi
        xorg.libXinerama
        xorg.libXmu
        xorg.libXrandr
        xorg.libXrender
        xorg.libXt
        xorg.libXtst
        xorg.libXxf86vm
        xorg.libpciaccess
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        xorg.xkeyboardconfig
        xz
        zlib
      ];
    };
    fuse = {
      userAllowOther = true;
    };
    ydotool = {
      enable = true;
      group = "wheel"; # not available in stable yet, so i have to add myself to ydotool group
    };
    # nix command line wrapper for ease of rebuilding
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 5";
      flake = "/home/liz/nix";
    };
  };
  hardware.steam-hardware.enable = true;

  # parsec alternative
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    autoStart = false;
  };

  # allow executing hard-coded shebangs like /bin/bash
  # needed for, e.g. jetbrains toolbox generated scripts
  services.envfs.enable = true;

  # enable virtual-manager
  # (vm configs stored in /var/lib/libvirt/qemu/)
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;
  # enable spice for virt-manager
  virtualisation.spiceUSBRedirection.enable = true;

  # vmware is giving me... wayyyy more trouble than it is worth
  # enable vmware virtualization (allows 3d acceleration in windows guests, unlike qemu/kvm)
  # virtualisation.vmware.host.enable = true;
  # Enable macos guest support
  # virtualisation.vmware.host.package = pkgs.vmware-workstation.override {enableMacOSGuests = true;};

  # enable containers (distrobox, docker, etc)
  virtualisation.containers.enable = true;

  # enable docker
  virtualisation.docker.enable = true;

  # enable waydroid for android apps
  # `waydroid session stop` to stop the session after opening an app
  # see nixos wiki for more info on setting this up (non-declaratively)
  virtualisation.waydroid.enable = true;

  # enable flatpak (managed with home-manager, just enabled here)
  services.flatpak.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    desktop-file-utils
    wget
    curl
    distrobox
    boxbuddy
    podman
    smem
    # game-devices-udev-rules # attempt at fixing steam input in wayland native games (not working)
    # easytether # my own packaging of easytether TODO needs fixes
    protontricks
    nvtopPackages.full
    pciutils
    intel-gpu-tools
    atop
    cmake
    gdb
    mono
    dotnet-sdk_7

    # btrfs/filesystem tools
    btrfs-progs
    rmlint
    duperemove
    bees
    btdu
    btrfs-heatmap
    btrbk
    compsize
    btrfs-assistant
    # overwritten desktop file to fix https://gitlab.com/btrfs-assistant/btrfs-assistant/-/issues/105
    # FIXED in 2.2, keeping this comment around for now as a reminder of how to do this sort of thing with symlinkJoin...
    # (pkgs.symlinkJoin {
    #   name = "btrfs-assistant-fixed";
    #   paths = [btrfs-assistant];
    #   postBuild = ''
    #     # remove linked desktop file
    #     rm $out/share/applications/btrfs-assistant.desktop
    #     # copy desktop file without link
    #     cp ${btrfs-assistant}/share/applications/btrfs-assistant.desktop $out/share/applications/btrfs-assistant.desktop
    #     # replace Exec line to fix issue
    #     # XDG_CURRENT_DESKTOP makes the theme work on KDE seemingly (i think i also had to set the theme properly in `systemsettings` as root)
    #     substituteInPlace $out/share/applications/btrfs-assistant.desktop \
    #       --replace "Exec=btrfs-assistant-launcher" 'Exec=sh -c "pkexec env DISPLAY=\\$DISPLAY XAUTHORITY=\\$XAUTHORITY XDG_CURRENT_DESKTOP=\\$XDG_CURRENT_DESKTOP WAYLAND_DISPLAY=\\$WAYLAND_DISPLAY XDG_RUNTIME_DIR=\\$XDG_RUNTIME_DIR btrfs-assistant-launcher"'
    #   '';
    # })
    # performance profiling
    config.boot.kernelPackages.perf

    # also needed for bluetooth lc3 codec
    # FUTURE: maybe enable for Bluetooth LE/LC3 when more stable
    # liblc3
  ];
  # services.udev.packages = [pkgs.easytether];
  # nixpkgs.config.permittedInsecurePackages = [
  #   "openssl-1.1.1w" # for easytether
  # ];

  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-7.0.410"
  ];

  # fix firefox emojis?
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      twemoji-color-font
    ];
    fontconfig = {
      useEmbeddedBitmaps = true;
    };
  };

  # systemd.network.enable = true;
  # systemd.services.NetworkManager-wait-online.enable = false;

  # allow spotify local discovery, warpinator port, misc port for things like local network udp obs stream
  networking.firewall.allowedTCPPorts = [42000 42001 57621 1234];
  networking.firewall.allowedUDPPorts = [42000 42001 5353 1234];

  # enable kernel stuff for obs virtual camera
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
  security.polkit.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = false;
    };
  };

  # enable magic sysrq
  boot.kernel.sysctl."kernel.sysrq" = 1;

  services.udev.extraHwdb = ''
    ## fix HP Envy autorotate causing airplane mode
    evdev:input:b0019v0000p0000e0000-*
      KEYBOARD_KEY_08=unknown

    ## Caps Lock to Backspace remap, at udev level so it works in games that take raw keyboard input
    # USB/HID keyboards ─ scancode 70039
    evdev:input:*
      KEYBOARD_KEY_70039=backspace

    # Internal PS/2 keyboards ─ scancode 3a
    evdev:atkbd:dmi:*
      KEYBOARD_KEY_3a=backspace
  '';

  # earlyoom to prevent freezes (better than oomd in my experience)
  # temp disabling this to see if increasing zram size fixes this issue
  systemd.oomd.enable = false;
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 8;
    freeMemKillThreshold = 4;
    freeSwapThreshold = 4;
    freeSwapKillThreshold = 2;
    enableNotifications = true;
    extraArgs = [
      "-r 0" # no periodic memory logging; change to 1 to print memory left once per sec
      "--prefer"
      "^(spotify|Web Content|Isolated Web Co)$"
      "--avoid"
      "^(btrfs|java|rclone|nix-index|nix-env|home-manager|nixos-rebuild|duplicacy|duplicati|rsync|packagekitd|gnome-shell|gnome-session-c|gnome-session-b|lightdm|sddm|sddm-helper|gdm|gdm-wayland-ses|gdm-session-wor|gdm-x-session|Xorg|Xwayland|systemd|systemd-logind|dbus-daemon|dbus-broker|cinnamon|cinnamon-sessio|kwin_x11|kwin_wayland|plasmashell|ksmserver|plasma_session|startplasma-way|sway|i3|xfce4-session|mate-session|marco|lxqt-session|openbox|cryptsetup)$"
    ];
  };

  # preload commonly-used files into RAM to speed up startups
  services.preload.enable = true;

  # enable swap
  # swapDevices = [
  #   {
  #     device = "/dev/disk/by-partuuid/d1de9241-a5f6-45c8-91b4-2b272d827d8e"; # /dev/nvme0n1p3
  #     randomEncryption.enable = true;
  #   }
  # ];
  # download more wam (compress RAM with zram)
  zramSwap.enable = true;
  # set zram to 75% of RAM (12GB on my system)
  # this should be fine; in real world use, i'm seeing a 4:1 to 5:1 compression ratio
  # higher values work fine but might be leading to sluggishness on my computer
  zramSwap.memoryPercent = 75;
  # optimize kernel parameters for zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  services.btrbk.instances = {
    # default instance
    btrbk = {
      # every 15 minutes
      onCalendar = "*-*-* *:00,15,30,45:00";
      settings = {
        timestamp_format = "long";
        snapshot_create = "onchange";
        snapshot_preserve_min = "3h";

        volume = {
          "/mnt/root" = {
            subvolume."@home" = {
              snapshot_preserve = "24h 7d 4w 6m 1y";
              snapshot_dir = "@home-snapshots";
            };
          };
          "/mnt/storage" = {
            subvolume."@" = {
              snapshot_preserve = "8h 3d 4w 2m 0y";
              snapshot_dir = "@snapshots";
            };
          };
          "/mnt/samsung_ssd" = {
            subvolume."@" = {
              snapshot_preserve = "8h 7d 0w 0m 0y";
              snapshot_dir = "@snapshots";
            };
          };
        };
      };
    };
  };

  # auto-scrub btrfs filesystems to detect errors (particularly, hardware failures)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = ["/" "/run/media/liz/storage"];
  };

  environment.etc."crypttab".text = ''
    # encrypted storage
    storage UUID=899fa394-16e9-4a75-9836-6f546fe70d5d /root/storage_keyfile luks,noauto,nofail
    # encrypted samsung ssd
    samsung_ssd UUID=cf38a1c4-902b-48e7-a262-b7862f1e4be9 /root/samsung_ssd_keyfile luks,noauto,nofail
    2tb_hdd UUID=7eedc760-957d-4d74-a6f3-0381106cd623 /root/2tb_hdd_keyfile luks,noauto,nofail
  '';

  # automount external devices with udev rules
  services.udev.extraRules = ''
    # auto unlock & mount sd card
    ACTION=="add", ENV{ID_FS_UUID}=="899fa394-16e9-4a75-9836-6f546fe70d5d", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@storage.service", ENV{SYSTEMD_WANTS}+="mnt-storage.mount", ENV{SYSTEMD_WANTS}+="run-media-liz-storage.mount"
    # auto unlock & mount samsung ssd
    ACTION=="add", ENV{ID_FS_UUID}=="cf38a1c4-902b-48e7-a262-b7862f1e4be9", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@samsung_ssd.service", ENV{SYSTEMD_WANTS}+="mnt-samsung_ssd.mount", ENV{SYSTEMD_WANTS}+="run-media-liz-samsung_ssd.mount"
    # auto unlock & mount 2tb hdd
    ACTION=="add", ENV{ID_FS_UUID}=="7eedc760-957d-4d74-a6f3-0381106cd623", ENV{SYSTEMD_WANTS}+="systemd-cryptsetup@2tb_hdd.service", ENV{SYSTEMD_WANTS}+="mnt-2tb_hdd.mount", ENV{SYSTEMD_WANTS}+="run-media-liz-2tb_hdd.mount"
  '';

  # limit journal size to 1GB
  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
