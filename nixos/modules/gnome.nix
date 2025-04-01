{
  lib,
  pkgs,
  config,
  ...
}: {
  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

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

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

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
}
