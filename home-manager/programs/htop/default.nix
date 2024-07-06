{
  pkgs,
  config,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  pathToHere = "${config.home.homeDirectory}/nix/home-manager/programs/htop";
in {
  programs.htop = {
    enable = true;
  };

  xdg.configFile = {
    # TODO make the path relative to flake dir somehow (still needs to expand to absolute path for nix reasons)
    "htop/htoprc".source = mkOutOfStoreSymlink "${pathToHere}/htoprc";
  };
}
