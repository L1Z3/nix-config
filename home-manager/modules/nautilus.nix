{
  lib,
  pkgs,
  config,
  home,
  ...
}: {
  # nautilus new file context menu options
  home.file."Templates/new".text = "";
  home.file."Templates/new.txt".text = "";
  home.file."Templates/new.sh".text = "";
  home.file."Templates/new.json".text = "";
}
