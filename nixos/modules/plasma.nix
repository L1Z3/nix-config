{
  lib,
  pkgs,
  config,
  ...
}: {
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

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
