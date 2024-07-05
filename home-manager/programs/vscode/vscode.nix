{
  pkgs,
  config,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  vsCodium = true;
  vsCodePackage =
    if vsCodium
    then pkgs.vscodium
    else pkgs.vscode;
  vsCodeDir =
    if vsCodium
    then "VSCodium"
    else "VSCode";
in {
  programs.vscode = {
    enable = true;
    package = vsCodePackage;
    extensions = with pkgs.vscode-extensions;
      [
        jnoortheen.nix-ide
        k--kato.intellij-idea-keybindings
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # add marketplace extensions not in nixpkgs here
        # {......
        #   name = "remote-ssh-edit";
        #   publisher = "ms-vscode-remote";
        #   version = "0.47.2";mkIf isLinux {
        #   sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        # }
      ];
  };

  xdg.configFile = {
    # "VSCode/User/keybindings.json".source =mkIf isLinux { keybindingsFile;
    # TODO make the path relative to flake dir somehow
    "${vsCodeDir}/User/settings.json".source = mkOutOfStoreSymlink "/home/liz/nix/programs/vscode/settings.json";
  };
}
