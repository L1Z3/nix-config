{pkgs, ...}:
pkgs.symlinkJoin rec {
  name = "qtcreator-with-deps";
  paths = [pkgs.qtcreator];
  buildInputs =
    [pkgs.makeWrapper]
    ++ [
      # pkgs.qt652-commit.qt6.full
      pkgs.qt6.full
      pkgs.gcc
      pkgs.cmake
      pkgs.cmake-format
      pkgs.coreutils-full
      pkgs.gnumake
      pkgs.gdb
      pkgs.libGL
      pkgs.glfw
      pkgs.openal
    ];
  # TODO infrasctructure for qtcreator to autodetect cmake, qmake, etc with env variables
  # TODO make it dark mode default

  postBuild = ''
    wrapProgram $out/bin/qtcreator \
      --prefix PATH : ${pkgs.lib.makeBinPath [
      # pkgs.qt652-commit.qt6.full
      pkgs.qt6.full
      pkgs.cmake
      pkgs.cmake-format
      pkgs.coreutils-full
      pkgs.gnumake
      pkgs.gdb
      pkgs.libGL
      pkgs.glfw
      pkgs.openal
    ]} \
      --set QT_PLUGIN_PATH ${pkgs.qt6.full}/lib/qt-${pkgs.qt6.qtbase.version}/plugins \
      --set QML2_IMPORT_PATH ${pkgs.qt6.full}/lib/qt-${pkgs.qt6.qtbase.version}/qml \
      --set QT_QMAKE_EXECUTABLE ${pkgs.qt6.full}/bin/qmake \
      --set QT_QPA_PLATFORM xcb \
      --set CC ${pkgs.gcc}/bin/gcc \
      --set CXX ${pkgs.gcc}/bin/g++ \
      --set GIO_MODULE_DIR ${pkgs.glib}/lib/gio/modules \
      --prefix CMAKE_PREFIX_PATH : ${pkgs.lib.makeSearchPath "lib/cmake" [
      pkgs.qt6.full
      pkgs.libGL
      pkgs.glfw
      pkgs.openal
    ]} \
    --prefix LD_LIBRARY_PATH : ${pkgs.qt6.full}/lib \
        --prefix PKG_CONFIG_PATH : ${pkgs.lib.makeSearchPath "lib/pkgconfig" [
      pkgs.qt6.full
      pkgs.libGL
      pkgs.glfw
      pkgs.openal
    ]}

    # --prefix XDG_DATA_DIRS : ${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
    # --set QT_STYLE_OVERRIDE adwaita \
    # --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs}:/run/opengl-driver/lib:/run/opengl-driver-32/lib \

    # we want to modify the desktop file to point to the wrapped qtcreator. we have to copy it since rn it's just a symlink
    desktopFile=$out/share/applications/org.qt-project.qtcreator.desktop
    rm $desktopFile
    cp ${pkgs.qtcreator}/share/applications/org.qt-project.qtcreator.desktop $desktopFile

    # Modify the Exec line in the .desktop file
    substituteInPlace $desktopFile \
      --replace "${pkgs.qtcreator}/bin/qtcreator" "$out/bin/qtcreator"
  '';
}
