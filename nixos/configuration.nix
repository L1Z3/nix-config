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

  # hardware.bluetooth.settings = {
  #   General = {
  #     Class = "0x002c0414";
  #   };
  # };
  # services.blueman.enable = true;

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # enable network printer discovery
  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
  };

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
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    # automatic garbage collection for system generations
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
      persistent = true;
    };
  };

  # FIXME: Add the rest of your current configuration

  networking.hostName = "envy";

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
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
      extraGroups = ["networkmanager" "wheel" "ydotool" "libvirtd" "qemu-libvirtd" "kvm"];
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
      # protontricks.enable = true; # only in unstable, TODO enable in future update
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
      ];
    };
    fuse = {
      userAllowOther = true;
    };
    ydotool = {
      enable = true;
      # group = "wheel"; # not available in stable yet, so i have to add myself to ydotool group
    };
  };
  hardware.steam-hardware.enable = true;

  # enable virtual-manager
  # (vm configs stored in /var/lib/libvirt/qemu/)
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;

  # enable flatpak
  services.flatpak.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    desktop-file-utils
    wget
    curl
    # easytether # my own packaging of easytether TODO needs fixes
  ];
  # services.udev.packages = [pkgs.easytether];
  # nixpkgs.config.permittedInsecurePackages = [
  #   "openssl-1.1.1w" # for easytether
  # ];

  # allow spotify local discovery
  networking.firewall.allowedTCPPorts = [57621];
  networking.firewall.allowedUDPPorts = [5353];

  # enable kernel stuff for obs virtual camera
  # boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
  # boot.kernelModules = [
  #   "v4l2loopback"
  # ];
  # OR these might be needed instead; TODO reboot and test which one works for obs
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
      "--prefer '^(spotify|Web Content|Isolated Web Co)$'"
      "--avoid '^(home-manager|nixos-rebuild|duplicacy|duplicati|rsync|packagekitd|gnome-shell|gnome-session-c|gnome-session-b|lightdm|sddm|sddm-helper|gdm|gdm-wayland-ses|gdm-session-wor|gdm-x-session|Xorg|Xwayland|systemd|systemd-logind|dbus-daemon|dbus-broker|cinnamon|cinnamon-sessio|kwin_x11|kwin_wayland|plasmashell|ksmserver|plasma_session|startplasma-way|sway|i3|xfce4-session|mate-session|marco|lxqt-session|openbox|cryptsetup)$'"
    ];
  };

  # enable swap
  # swapDevices = [ {
  #   device = "/swapfile";
  #   size = 8*1024;
  # } ];
  zramSwap.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
