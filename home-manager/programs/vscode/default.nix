{
  pkgs,
  config,
  extensions,
  lib,
  secrets,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  pathToHere = "${config.home.homeDirectory}/nix/home-manager/programs/vscode";

  vsCodium = false; # random thing for a cs course breaks with vscodium
  vsCodePackage =
    if vsCodium
    then pkgs.vscodium
    else pkgs.vscode;
  vsCodeDir =
    if vsCodium
    then "VSCodium"
    else "Code";
in {
  programs.vscode = {
    enable = true;
    package = vsCodePackage;
    profiles.default.extensions = with pkgs.vscode-extensions;
      [
        jnoortheen.nix-ide
        k--kato.intellij-idea-keybindings
        github.copilot
        github.copilot-chat
        mkhl.direnv
        ms-vscode-remote.remote-containers
        ms-vscode.cpptools-extension-pack
        # asvetliakov.vscode-neovim
        ms-vscode-remote.remote-ssh
        # catppuccin theme # actually, these can't easily be installed declaratively due to the decarlative option conflicting with my other vscode setitngs here
        # catppuccin.catppuccin-vsc
        # catppuccin.catppuccin-vsc-icons
      ]
      ++ (with extensions.vscode-marketplace-release; [
        # add non-nixpkgs extensions here
      ]);
  };

  # language server
  home.packages = with pkgs; [
    # nil
    unstable.nixd # unstable so i can have 2.2.2 hover feature
  ];
  xdg.configFile = {
    # "VSCode/User/keybindings.json".source =mkIf isLinux { keybindingsFile;
    # TODO make the path relative to flake dir somehow (still needs to expand to absolute path for nix reasons)
    "${vsCodeDir}/User/settings.json".source = lib.mkForce (mkOutOfStoreSymlink "${pathToHere}/settings.json");
  };
}
