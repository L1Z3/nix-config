# TODO THIS IS A DRAFT. IT DOES NOT WORK YET
#       current progress: the client attempts to start, fails with `realloc(): invalid pointer`, then successfully launches the crash report GUI
{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  writeShellScript,
  buildFHSEnv,
  xkeyboard_config,
  pkgs,
}: let
  pname = "piavpn";
  version = "3.5.7-08120";

  pia-pkg = stdenv.mkDerivation rec {
    name = "${pname}-${version}";
    src = fetchurl {
      url = "https://installers.privateinternetaccess.com/download/pia-linux-${version}.run";
      sha256 = "sha256-QVlIGqSXerSwZtqeLvjmQS/p7Z1JJIPWQLWQj+ZA6/g=";
    };

    unpackPhase = ''
      cp $src $TMPDIR/download.run
      chmod +x $TMPDIR/download.run
      $TMPDIR/download.run --noexec --target .
    '';

    buildInputs = with pkgs;
    with pkgs.xorg; [
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
      qt5.full
    ];

    dontWrapQtApps = true;

    preFixup = ''
      wrapQtApp "$out/opt/piavpn/bin/pia-client" --prefix LD_LIBRARY_PATH : $out/opt/piavpn/lib
    '';

    nativeBuildInputs = [
      autoPatchelfHook
      pkgs.qt5.wrapQtAppsHook
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/piavpn/bin
      cp -a ./piafiles/* $out/opt/piavpn

      # temp hack, patchelf not working on this binary
      rm -f $out/opt/piavpn/bin/pia-unbound

      cp installfiles/*.sh $out/opt/piavpn/bin
      chmod +x $out/opt/piavpn/bin/*.sh
      # setcap 'cap_net_bind_service=+ep' $out/opt/piavpn/bin/pia-unbound
      # we don't need these scripts
      rm $out/opt/piavpn/bin/install-wireguard.sh
      rm $out/opt/piavpn/bin/pia-uninstall.sh

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
       mv $out/opt/piavpn/share/LICENSE.txt $out/share/licenses/${pname}/

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
  };
in
  buildFHSEnv rec {
    inherit pname version;

    runScript = writeShellScript "pia-launch.sh" ''
      # export QT_QPA_PLATFORM=xcb

      ${pia-pkg}/opt/piavpn/bin/pia-client "$@"
      # bash
    '';
    #   ];

    # unshareUser = false;
    # unshareIpc = false;
    # unsharePid = false;
    # unshareNet = false;
    # unshareUts = false;
    # unshareCgroup = false;

    # dieWithParent = true;

    extraBwrapArgs = [
      "--tmpfs /opt"
      "--ro-bind ${pia-pkg}/opt/piavpn/bin /opt/piavpn/bin"
      "--ro-bind ${pia-pkg}/opt/piavpn/lib /opt/piavpn/lib"
      "--ro-bind ${pia-pkg}/opt/piavpn/share /opt/piavpn/share"
      "--ro-bind ${pia-pkg}/opt/piavpn/plugins /opt/piavpn/plugins"
      "--ro-bind ${pia-pkg}/opt/piavpn/qml /opt/piavpn/qml"
    ];

    extraInstallCommands = ''
      mkdir -p "$out/share/applications"
      mkdir -p "$out/share/pixmaps"
      ln -s ${pia-pkg}/share/applications/*.desktop "$out/share/applications/"
      ln -s ${pia-pkg}/share/pixmaps/*.png "$out/share/pixmaps"
      # cp $out/opt/piavpn/lib/libQt5* $out/lib
    '';
  }
