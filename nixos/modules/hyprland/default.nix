{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  hyprpkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in {
  programs.hyprland = {
    enable = true;
    withUWSM = true; # better systemd integration
    xwayland.enable = true;
    # set the flake package
    package = hyprpkg.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = hyprpkg.xdg-desktop-portal-hyprland;
  };
  # ly + uwsm failed to start hyprland, so we use regreet for now (config taken from https://github.com/dearfl/nyx/blob/aa8a023e4638ca76fceaaf1e94b006ac8c60dcd1/hosts/optional/hyprland.nix#L4)
  services.greetd.enable = true;
  programs.regreet.enable = true;
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
      };
    };
  };

  programs.xwayland.enable = true;
  # TODO monitor config?
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
