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

    ly.enable = true;
  };
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xorg.libXcursor
    hyprland-qtutils
    hyprland-qt-support
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
        # see https://github.com/subframe7536/Maple-font for more details
        maple-mono.truetype
        maple-mono.NF-unhinted
        maple-mono.NF-CN-unhinted

        twemoji-color-font
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
