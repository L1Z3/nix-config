{
  lib,
  python3Packages,
  hyprland,
  wofi,
  gtk3,
  gobject-introspection,
  wrapGAppsHook3,
}:
python3Packages.buildPythonApplication {
  pname = "window-search";
  version = "1.0.0";

  src = ./.;

  format = "script";

  propagatedBuildInputs = [
    python3Packages.pygobject3
    gtk3
    gobject-introspection
  ];

  nativeBuildInputs = [
    wrapGAppsHook3
    gobject-introspection
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ./window-search.py $out/bin/window-search
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [
      hyprland
      wofi
      gtk3
    ]}
      )
  '';

  meta = with lib; {
    description = "Python script to switch between Hyprland windows using wofi";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "window-search";
  };
}
