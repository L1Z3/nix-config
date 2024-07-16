{
  fetchurl,
  appimageTools,
  ...
}: let
  appimage-file = fetchurl {
    url = "https://archive.org/download/yuzu-windows-msvc-20240304-537296095_20240305_1340/Linux/Linux-Yuzu-EA-4176.AppImage";
    sha256 = "sha256-bUTVL8br2POy5HB1FszlNQNChdRWcwIlG6/RCceXIlg=";
  };
in
  appimageTools.wrapType2 {
    name = "yuzu";
    version = "EA-4176";
    src = appimage-file;
  }
