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

  # idk if these help, scrounged together from various wikis/forums
  boot.kernelParams = ["nvidia.NVReg_EnableResizableBar=1" "nvidia.NVreg_UsePageAttributeTable=1"];

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Use Nvidia Prime to choose which GPU (iGPU or eGPU) to use.
    prime = {
      # sync.enable = true;
      offload.enable = true;
      # offload.enableOffloadCmd = true; # custom version instead, see environment.systemPackages
      allowExternalGpu = true;

      # Make sure to use the correct Bus ID values for your system!
      nvidiaBusId = "PCI:46:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # allow hotplugging? idk see arch wiki https://wiki.archlinux.org/title/External_GPU#Hotplugging_NVIDIA_eGPU
  # also needs custom nvidia-offload script (see below)
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
