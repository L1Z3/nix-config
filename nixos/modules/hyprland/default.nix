{
  lib,
  pkgs,
  config,
  ...
}: {
  programs.hyprland = {
    enable = true;
    withUWSM = true; # better systemd integration
    xwayland.enable = true;
  };
  programs.xwayland.enable = true;
  # TODO monitor config?
  services.displayManager = {
    defaultSession = "hyprland-uwsm";

    sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [sddm-astronaut];
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      theme = "sddm-astronaut-theme";
      settings.Theme.CursorTheme = "Bibata-Modern-Ice";
    };
  };
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xorg.libXcursor
    hyprland-qtutils
    hyprland-qt-support
    sddm-astronaut
    bibata-cursors
  ];

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
    };
    packages = with pkgs;
      [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf
        roboto-mono
        font-awesome
        jetbrains-mono
        corefonts
      ]
      ++ builtins.filter lib.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };
}
