{
  lib,
  pkgs,
  config,
  ...
}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  services.switcherooControl.enable = true;
  # fix switcherooctl python error by pulling in PR https://github.com/NixOS/nixpkgs/pull/375411
  services.switcherooControl.package = let
    pkgs-fixed-switcheroo = import (builtins.fetchTarball {
      url = "https://github.com/vasi/nixpkgs/archive/2a16a8a27f7aa1b89511de338a64ecbf3658aa85.tar.gz";
      sha256 = "sha256:068yc2ijyq139fpa7j1drhdbc3162nasahfy45nb82fdi9rfcbyn";
    }) {system = pkgs.system;};
  in
    pkgs-fixed-switcheroo.switcheroo-control;

  # idk if these help, scrounged together from various wikis/forums
  boot.kernelParams = ["nvidia.NVReg_EnableResizableBar=1" "nvidia.NVreg_UsePageAttributeTable=1"];

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # i never quite figured out what this does/if it helps
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # open source driver is recommended for RTX 40 series afaik
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Use Nvidia Prime to choose which GPU (iGPU or eGPU) to use.
    prime = {
      # sync.enable = true; # TODO maybe try sync again?
      offload.enable = true;
      # offload.enableOffloadCmd = true; # custom version instead, see environment.systemPackages below
      allowExternalGpu = true;

      # Make sure to use the correct Bus ID values for your system!
      nvidiaBusId = "PCI:46:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # allow hotplugging? idk see arch wiki https://wiki.archlinux.org/title/External_GPU#Hotplugging_NVIDIA_eGPU
  # also needs custom nvidia-offload script (see below)
  # edit: hotplugging (for first time on boot) works, but not after unplugging and replugging
  environment.sessionVariables = {
    __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
  };

  environment.systemPackages = [
    # custom version of nvidia-offload command to do the thing that arch wiki says https://wiki.archlinux.org/title/External_GPU#Hotplugging_NVIDIA_eGPU
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export __EGL_VENDOR_LIBRARY_FILENAMES=${config.boot.kernelPackages.nvidiaPackages.stable}/share/glvnd/egl_vendor.d/10_nvidia.json
      exec "$@"
    '')
  ];
}
