# TODO THIS IS A DRAFT. IT DOES NOT WORK YET

{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  qt5,
  libxkbcommon,
  libX11,
  libglvnd,
  libgcc,
  libXext,
  fontconfig,
  freetype,
  libXcomposite,
  glib,
  libdrm,
}:
stdenv.mkDerivation rec {
  pname = "piavpn";
  version = "3.5.7-08120";

  src = fetchurl {
    url = "https://installers.privateinternetaccess.com/download/pia-linux-${version}.run";
    sha256 = "sha256-QVlIGqSXerSwZtqeLvjmQS/p7Z1JJIPWQLWQj+ZA6/g=";
  };

  unpackPhase = ''
    cp $src $TMPDIR/download.run
    chmod +x $TMPDIR/download.run
    $TMPDIR/download.run --noexec --target .
  '';

  buildInputs = [
    libxkbcommon
    libX11
    libXext
    libglvnd
    libgcc.lib
    fontconfig.lib
    freetype
    libXcomposite
    glib
    libdrm

    qt5.qtbase
    qt5.qtlocation
    qt5.qt3d
    qt5.qtremoteobjects
    qt5.qtxmlpatterns
    qt5.qtgamepad
    # qt5.full
  ];

  # runtimeInputs = [

  # ];

  # qtWrapperArgs = let
  #   runtimeLibs = [
  #     libxkbcommon
  #     libX11
  #     libXext
  #     libglvnd
  #     libgcc.lib
  #     fontconfig.lib
  #     freetype
  #     libXcomposite
  #     glib
  #     libdrm
  #   ];
  # in [
  #   "--prefix LD_LIBRARY_PATH $out/lib:${lib.makeLibraryPath runtimeLibs}"
  # ];

  # qtWrapperArgs = [
  #   "--prefix LD_LIBRARY_PATH $out/lib:${lib.makeLibraryPath runtimeLibs}"
  # ];
  dontWrapQtApps = true;

  # preFixup = ''
  #   wrapProgram "$out/bin/pia-unbound" --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
  #     libxkbcommon
  #     libX11
  #     libXext
  #     libglvnd
  #     libgcc.lib
  #     fontconfig.lib
  #     freetype
  #     libXcomposite
  #     glib
  #     libdrm
  #    ]}
  #   wrapQtApp "$out/lib/noson/noson-gui"
  # '';

  # TODO: currently things begin launching, support_tool_launcher complains about missing files in /opt/piavpn
  #       i probably need to rethink approach and create FHS environment and preserve intended dir structure
  /*
   see lines from log:
  [2024-07-24 00:38:44.627][6b5b][common.util][src/builtin/util.cpp:117][debug] Starting support tool at  "/nix/store/08ish55lgdzzgfsjlnc1jfhhx9gqb8rf-piavpn-3.5.7-08120/bin/support-tool-launcher"
  [2024-07-24 00:38:44.627][6b5b][common.util][src/builtin/util.cpp:118][debug] ("--mode", "crash", "--log", "/home/liz/.local/share/privateinternetaccess/client.log", "--log", "/opt/piavpn/var/daemon.log", "--log", "/home/liz/.local/share/privateinternetaccess/cli.log", "--log", "/opt/piavpn/var/config.log", "--log", "/opt/piavpn/var/updown.log", "--client-crashes", "/home/liz/.local/share/privateinternetaccess/crashes", "--daemon-crashes", "/opt/piavpn/var/crashes", "--client-settings", "/home/liz/.config/privateinternetaccess/clientsettings.json", "--api-override", "/opt/piavpn/etc/api_override.json")
  exec err: -1 / 2 - No such file or directory
  */
  preFixup = ''
    wrapQtApp "$out/bin/pia-client" --prefix LD_LIBRARY_PATH : $out/lib:${lib.makeLibraryPath [
      libxkbcommon
      libX11
      libXext
      libglvnd
      libgcc.lib
      fontconfig.lib
      freetype
      libXcomposite
      glib
      libdrm
    ]} --prefix QML2_IMPORT_PATH : $out/qml:$out/qml/Qt:$out/qml/QtQml:$out/qml/QtGraphicalEffects:$out/qml/QtQuick:$out/qml/QtQuick2


  '';

  nativeBuildInputs = [
    autoPatchelfHook
    qt5.wrapQtAppsHook
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a ./piafiles/* $out
    chmod +x $out/bin/pia-* $out/bin/*.sh $out/bin/support-tool-launcher
    # setcap 'cap_net_bind_service=+ep' $out/opt/piavpn/bin/pia-unbound

    mkdir -p $out/share/pixmaps
    cp ./installfiles/app-icon.png $out/share/pixmaps/piavpn.png
    mkdir -p $out/share/icons/hicolor/1024x1024/apps/
    # ln -s $out/share/pixmaps/pia.png $out/usr/share/icons/hicolor/1024x1024/apps/pia.png
    mkdir -p $out/share/applications
    cp ./installfiles/piavpn.desktop $out/share/applications/piavpn.desktop
    # mkdir -p $out/etc/NetworkManager/conf.d
    # echo -e "[keyfile]\nunmanaged-devices=interface-name:wgpia*" > $pkgdir/etc/NetworkManager/conf.d/50-wgpia.conf

    # mkdir -p $pkgdir/usr/lib/systemd/system
    # cp installfiles/piavpn.service $pkgdir/usr/lib/systemd/system/piavpn.service
    # sed -i '/^After/s/syslog.target //' $pkgdir/usr/lib/systemd/system/piavpn.service

     mkdir -p $out/share/licenses/${pname}/
     mv $out/share/LICENSE.txt $out/share/licenses/${pname}/

     # fix permissions: no need for executable bit
    #  find $out/usr -type f -exec chmod -x {} \;

    #  mkdir -p $out/usr/local/bin
     # ln -s ../../../opt/piavpn/bin/piactl $pkgdir/usr/local/bin/piactl

     # limit log to the minimum to avoid excessive flooding
     # mkdir -p $out/opt/piavpn/var
     # cat > $out/opt/piavpn/var/debug.txt << EOF
     # [rules]
     # *.debug=false
     # *.info=false
     # *.warning=false
     # EOF

     runHook postInstall
  '';

  meta = with lib; {
    # description = ";
    # homepage = "";
    # license = with licenses; [ ... ];
    # platforms = platforms.linux;
    # maintainers = with maintainers; [ ... ];
  };
}
