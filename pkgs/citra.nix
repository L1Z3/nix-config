{
  fetchzip,
  appimageTools,
  p7zip,
  ...
}: let
  pname = "citra";
  version = "20240303";

  filename = "citra-qt";

  src = fetchzip {
    url = "https://archive.org/download/citra-nightly-2104_20240304/citra-linux-appimage-20240303-0ff3440.7z";
    sha256 = "sha256-KQEp3y1YjeMrezG0D4H/A52VNer4j3HW6Myeong34o4=";
    nativeBuildInputs = [p7zip];
  };

  appimage-contents = appimageTools.extract {
    inherit pname version;
    src = "${src}/${filename}.AppImage";
  };
in
  appimageTools.wrapAppImage {
    inherit pname version;
    src = appimage-contents;
    extraInstallCommands = ''
      install -m 444 -D ${appimage-contents}/${filename}.desktop -t $out/share/applications
      cp -r ${appimage-contents}/usr/share/icons $out/share
    '';
  }
