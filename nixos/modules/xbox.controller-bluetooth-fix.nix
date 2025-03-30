{config, ...}: {
  hardware.xpadneo.enable = true;

  # hardware.bluetooth.settings = {
  #   General = {
  #     Privacy = "device";
  #     JustWorksRepairing = "always";
  #     Class = "0x000100";
  #     FastConnectable = true;
  #   };
  # };

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [xpadneo];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
  };
}
