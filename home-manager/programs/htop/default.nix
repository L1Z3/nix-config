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

  # htoprc needs to be editable by htop, so set env to point to htoprc in the flake, not in the store
  # TODO make the path relative to flake dir somehow (still needs to expand to absolute path)
  home.sessionVariables = {
    HTOPRC = "${pathToHere}/htoprc";
  };

  # xdg.configFile = {
  #   # TODO fix this symlink getting overwritten by htop
  #   "htop/htoprc".source = mkOutOfStoreSymlink "${pathToHere}/htoprc";
  # };
}
