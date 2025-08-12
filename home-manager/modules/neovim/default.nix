{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  thisDir = "${config.home.homeDirectory}/nix/home-manager/modules/neovim";
in {
  programs.neovim = {
    enable = true;
    extraConfig = ''
      :source ${mkOutOfStoreSymlink "${thisDir}/init.vim"}
    '';
  };
}
