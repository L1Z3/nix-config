{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  hyprpkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  pkgs-hypr = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
  # ly + uwsm failed to start hyprland, so we use tuigreet for now
  services.greetd = {
    enable = true;
    # restart = true;
    # vt = 1; # tty
    settings = {
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
        user = "greeter";
      };
      # default_session = {
      #   command = "${pkgs.greetd.tuigreet}/bin/tuigreet -w 69 -t --time-format '%B, %A %d @ %H:%M:%S' -r --remember-session --asterisks --user-menu -g 'Password: ********' --container-padding 1 --prompt-padding 0 --theme 'border=magenta;text=white;prompt=cyan;time=green;action=yellow;button=red;container=black;input=white'";
      #   user = "greeter";
      # };
    };
  };
  # optional below
  # systemd.services.greetd.serviceConfig = {
  #   Type = "idle";
  #   StandardInput = "tty";
  #   StandardOutput = "null"; # no tty spam
  #   StandardError = "journal";
  #   TTYReset = true;
  #   TTYVHangup = true;
  #   TTYVTDisallocate = true;
  # };
  # programs.uwsm = {
  #   enable = true;
  #   waylandCompositors = {
  #     hyprland = {
  #       prettyName = "Hyprland";
  #       comment = "Hyprland compositor managed by UWSM";
  #       binPath = "/run/current-system/sw/bin/Hyprland";
  #     };
  #   };
  # };

  programs.xwayland.enable = true;
  # TODO monitor config?
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xorg.libXcursor
    pkgs-hypr.hyprland-qtutils
    pkgs-hypr.hyprland-qt-support
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
