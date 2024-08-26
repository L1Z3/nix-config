{
  fetchurl,
  appimageTools,
  ...
}: let
  pname = "yuzu";
  version = "EA-4176";

  # archive.org page was nuked by Nintendo
  # src = fetchurl {
  #   url = "https://archive.org/download/yuzu-windows-msvc-20240304-537296095_20240305_1340/Linux/Linux-Yuzu-EA-4176.AppImage";
  #   sha256 = "sha256-bUTVL8br2POy5HB1FszlNQNChdRWcwIlG6/RCceXIlg=";
  # };

  # src = builtins.path {
  #   name = "Linux-Yuzu-EA-4176.AppImage";
  #   path = /home/liz/Applications/Linux-Yuzu-EA-4176.AppImage;
  #   sha256 = "sha256-bUTVL8br2POy5HB1FszlNQNChdRWcwIlG6/RCceXIlg=";
  # };

  src = /home/liz/Applications/Linux-Yuzu-EA-4176.AppImage;

  appimage-contents = appimageTools.extract {
    inherit pname version src;
  };

  desktop-file-name = "org.yuzu_emu.yuzu";
in
  appimageTools.wrapAppImage {
    inherit pname version;
    src = appimage-contents;
    extraInstallCommands = ''
      install -m 444 -D ${appimage-contents}/${desktop-file-name}.desktop -t $out/share/applications
      cp -r ${appimage-contents}/usr/share/icons $out/share
    '';
  }
