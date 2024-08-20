{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  # winapps dependencies
  home.packages = with pkgs; [
    dialog
    freerdp3
    iproute2
    libnotify
    netcat-gnu
  ];
  # TODO find a way to refer to this winapps.conf file through the flake
  xdg.configFile."winapps/winapps.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/secrets/winapps.conf";
}
