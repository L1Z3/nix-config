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
    # ./users.nix

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

  # switching to latest kernel temporaily until LTS goes past 6.9 (to fix HP Envy speakers)
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # automatic screen rotation in GNOME
  hardware.sensor.iio.enable = true;

  # enable gnome debug settings (specifically, i want to enable the session management protocol that is experimental in gnome 47)
  # edit: this isn't useful yet because no applications use it. TODO i realllly want a fork/patch of firefox that uses it....
  # systemd.user.services."org.gnome.Shell@wayland" = {
  #   overrideStrategy = "asDropin";
  #   path = lib.mkForce [];
  #   serviceConfig = {
  #     Environment = [
  #       ""
  #       "MUTTER_DEBUG_SESSION_MANAGEMENT_PROTOCOL=1"
  #     ];
  #     ExecStart = [
  #       ""
  #       "${pkgs.gnome-shell}/bin/gnome-shell --debug-control"
  #     ];
  #   };
  # };

  # get rid of gnome software
  environment.gnome.excludePackages =
    (with pkgs; [
      # for packages that are pkgs.*
      gnome-software
    ])
    ++ (with pkgs.gnome; [
      # for packages that are pkgs.gnome.*
    ]);

  # hack to transfer gnome monitor config to gdm
  systemd.tmpfiles.rules = [
    "C+ /run/gdm/.config/monitors.xml - - - - /home/liz/.config/monitors.xml"
  ];

  # TODO try hyprland sometime

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # temporarily disable printing (CUPS CVE)
  # Enable CUPS to print documents.
  # services.printing = {
  #   enable = true;
  #   drivers = with pkgs; [gutenprint canon-cups-ufr2 cups-filters];
  # };
  # enable network printer discovery
  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  #   openFirewall = true;
  # };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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
    # hardware.graphics on unstable
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime # for davinci resolve
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {LIBVA_DRIVER_NAME = "iHD";}; # Force intel-media-driver

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
      extraGroups = ["networkmanager" "wheel" "libvirtd" "qemu-libvirtd" "kvm" "docker"];
    };
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
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

  # allow executing hard-coded shebangs like /bin/bash
  # needed for, e.g. jetbrains toolbox generated scripts
  services.envfs.enable = true;

  # enable virtual-manager
  # (vm configs stored in /var/lib/libvirt/qemu/)
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;
  # enable spice for virt-manager
  virtualisation.spiceUSBRedirection.enable = true;

  # enable vmware virtualization (allows 3d acceleration in windows guests, unlike qemu/kvm)
  virtualisation.vmware.host.enable = true;
  # Enable macos guest support
  virtualisation.vmware.host.package = pkgs.vmware-workstation.override {enableMacOSGuests = true;};

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
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    desktop-file-utils
    wget
    curl
    distrobox
    boxbuddy
    podman
    # game-devices-udev-rules # attempt at fixing steam input in wayland native games (not working)
    # easytether # my own packaging of easytether TODO needs fixes
    protontricks

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

  # systemd.network.enable = true;
  # systemd.services.NetworkManager-wait-online.enable = false;
  # systemd.network.networks."99-tun-easytether" = {
  #   enable = true;
  #   extraConfig = ''
  #     [Match]
  #     Name=tun-easytether

  #     [Network]
  #     Description=EasyTether IPv4-only network
  #     DNS=192.168.117.1

  #     [Address]
  #     Address=192.168.117.0/31
  #     Peer=192.168.117.1/31
  #     Broadcast=255.255.255.255

  #     [Route]
  #     Gateway=192.168.117.1
  #   '';
  # };
  # networking.networkmanager.ensureProfiles.profiles = {
  #   tap-easytether = {
  #     connection = {
  #       autoconnect = "no";
  #       id = "EasyTether";
  #       interface-name = "tap-easytether";
  #       read-only = "yes";
  #       type = "tun";
  #       uuid = "04366dd5-8fe6-483c-b675-cf05f1650cc2";
  #     };
  #     ipv4 = {method = "auto";};
  #     ipv6 = {
  #       addr-gen-mode = "stable-privacy";
  #       method = "link-local";
  #     };
  #     tun = {mode = "2";};
  #   };
  # };
  # networking.interfaces.tap-easytether.useDHCP = true;
  # networking.networkmanager.dhcp = "dhcpcd";

  # allow spotify local discovery, misc port for things like local network udp obs stream
  networking.firewall.allowedTCPPorts = [57621 1234];
  networking.firewall.allowedUDPPorts = [5353 1234];

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

  # qemu guest additions
  # services.qemuGuest.enable = true;
  # services.spice-vdagentd.enable = true;

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = false;
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

  # fix HP Envy autorotate causing airplane mode
  services.udev.extraHwdb = ''
    evdev:input:b0019v0000p0000e0000-*
      KEYBOARD_KEY_08=unknown
  '';

  # earlyoom to prevent freezes (better than oomd in my experience)
  # temp disabling this to see if increasing zram size fixes this issue
  # systemd.oomd.enable = false;
  # services.earlyoom = {
  #   enable = true;
  #   freeMemThreshold = 8;
  #   freeMemKillThreshold = 4;
  #   freeSwapThreshold = 4;
  #   freeSwapKillThreshold = 2;
  #   enableNotifications = true;
  #   extraArgs = [
  #     "-r 0" # no periodic memory logging; change to 1 to print memory left once per sec
  #     "--prefer '^(spotify|Web Content|Isolated Web Co)$'"
  #     "--avoid '^(nix-index|nix-env|home-manager|nixos-rebuild|duplicacy|duplicati|rsync|packagekitd|gnome-shell|gnome-session-c|gnome-session-b|lightdm|sddm|sddm-helper|gdm|gdm-wayland-ses|gdm-session-wor|gdm-x-session|Xorg|Xwayland|systemd|systemd-logind|dbus-daemon|dbus-broker|cinnamon|cinnamon-sessio|kwin_x11|kwin_wayland|plasmashell|ksmserver|plasma_session|startplasma-way|sway|i3|xfce4-session|mate-session|marco|lxqt-session|openbox|cryptsetup)$'"
  #   ];
  # };

  # enable swap
  # swapDevices = [ {
  #   device = "/swapfile";
  #   size = 8*1024;
  # } ];
  # download more wam (compress RAM with zram)
  zramSwap.enable = true;
  # set zram to 50% of RAM (8GB on my system)
  # this should be fine; in real world use, i'm seeing a 4:1 to 5:1 compression ratio
  # higher values work fine but might be leading to sluggishness on my computer
  zramSwap.memoryPercent = 50;
  # optimize kernel parameters for zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 130;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
