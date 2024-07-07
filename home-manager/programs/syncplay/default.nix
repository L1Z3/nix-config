{
  pkgs,
  config,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  pathToHere = "${config.home.homeDirectory}/nix/home-manager/programs/syncplay";
in {
  home.packages = with pkgs; [
    unstable.syncplay
  ];

  xdg.configFile = {
    # TODO make the path relative to flake dir somehow (still needs to expand to absolute path for nix reasons)
    "syncplay.ini".source = mkOutOfStoreSymlink "${pathToHere}/syncplay.ini";
  };
}
