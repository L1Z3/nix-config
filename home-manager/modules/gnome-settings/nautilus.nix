{
  lib,
  pkgs,
  config,
  home,
  ...
}: {
  # nautilus bookmarks
  # gtk.gtk3.bookmarks = nautilusBookmarks;
  # actually, it's more convenient to just have this symlink'd
  # actually actually, looks like in gnome 47, nautlius will override the symlink
  # home.file.".config/gtk-3.0/bookmarks".source =
  #   config.lib.file.mkOutOfStoreSymlink
  #   "${config.home.homeDirectory}/nix/secrets/nautilus-bookmarks";

  # nautilus new file context menu options
  home.file."Templates/new".text = "";
  home.file."Templates/new.txt".text = "";
  home.file."Templates/new.sh".text = "";
  home.file."Templates/new.json".text = "";
}
