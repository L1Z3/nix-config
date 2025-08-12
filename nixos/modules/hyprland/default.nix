{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  # hyprpkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  # pkgs-hypr = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  hyprpkg = pkgs;
  pkgs-hypr = pkgs;
  theme-colors = {
    accent = "#cba6f7";
    accent-deep = "#cba6f7";
    dark = "#11111b";
    lighter-dark = "#181825";
    foreground = "#cdd6f4";
    complementary-accent = "#74c7ec";
    warning = "#fab387";
    danger = "#f38ba8";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    blue = "#89b4fa";
    cyan = "#89dceb";
    magenta = "#cba6f7";
  };
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
    restart = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd 'loginctl terminate-user \"\"; exec uwsm start hyprland-uwsm.desktop' -w 69 -t --time-format '%B, %A %d @ %H:%M:%S' -r --remember-session --asterisks --user-menu --config /etc/greetd/tuigreet.toml --greeting 'Welcome to NixOS' --greeting-color '#cba6f7'";
        user = "greeter";
      };
    };
  };

  # tuigreet theme configuration to match Catppuccin Mocha Mauve
  environment.etc."greetd/tuigreet.toml".text = ''
    # Catppuccin Mocha Mauve theme for tuigreet
    [theme]
    background = "#1e1e2e"
    container_background = "#313244"

    text = "#cdd6f4"
    prompt = "#cba6f7"
    time = "#89b4fa"
    action = "#f9e2af"
    button = "#cba6f7"
    input = "#cdd6f4"
    label = "#6c7086"

    border = "#cba6f7"
    input_border = "#6c7086"
    button_border = "#cba6f7"

    error = "#f38ba8"
    success = "#a6e3a1"
    warning = "#fab387"

    container_padding = 2
    prompt_padding = 1
    border_width = 2
    border_radius = 12

    font_family = "Maple Mono"
    font_size = 14
    prompt_font_size = 16
    time_font_size = 18
    label_font_size = 12

    button_padding = 8
    input_padding = 6
    spacing = 4
  '';
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "null"; # no tty spam
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # enable auto-rotate in hyprland
  programs.iio-hyprland.enable = true;

  # enable hyprpanel's power profile switching
  services.power-profiles-daemon.enable = true;
  # make hyprpanel battery indicator work
  services.upower.enable = true;

  programs.xwayland.enable = true;
  # TODO monitor config?
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # allow root apps (e.g. btrfs-assistant) to use qt kvantum catppuccin theme
  qt = {
    enable = true;
    style = "kvantum";
  };
  environment.etc."xdg/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-mauve
  '';
  systemd.tmpfiles.rules = [
    "L+ /root/.config/Kvantum/catppuccin-mocha-mauve - - - - ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.kvantum}/share/Kvantum/catppuccin-mocha-mauve"
    "L+ /root/.config/Kvantum/kvantum.kvconfig - - - - /etc/xdg/Kvantum/kvantum.kvconfig"
  ];

  environment.systemPackages = with pkgs; [
    xorg.libXcursor
    pkgs-hypr.hyprland-qtutils
    pkgs-hypr.hyprland-qt-support
    bibata-cursors
    networkmanager
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
