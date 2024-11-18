{
  pkgs,
  config,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  home.packages = with pkgs; [
    # unstable.syncplay # due to some weird bug, switching to stable
    syncplay
  ];

  xdg.configFile = {
    # TODO make the path relative to flake dir somehow (still needs to expand to absolute path for nix reasons)
    "syncplay.ini".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/secrets/syncplay.ini";
  };
}
