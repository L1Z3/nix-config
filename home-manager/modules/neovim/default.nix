{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  thisDir = "${config.home.homeDirectory}/nix/home-manager/modules/neovim";
  vimDir = "${config.home.homeDirectory}/.config/nvim";
in {
  programs.neovim = {
    enable = true;
    extraConfig = ''
      :source ${mkOutOfStoreSymlink "${vimDir}/main.vim"}
    '';
  };
  xdg.configFile = {
    "nvim/main.vim".source = mkOutOfStoreSymlink "${thisDir}/main.vim";
    "nvim/vscode/init.vim".source = mkOutOfStoreSymlink "${thisDir}/vscode-init.vim";
  };
}
