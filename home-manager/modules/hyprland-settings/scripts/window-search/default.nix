# default.nix
{
  lib,
  python3Packages,
  hyprland,
  wofi,
  gtk3,
}:
python3Packages.buildPythonApplication {
  pname = "window-search";
  version = "1.0.0";

  src = ./.;

  # FIX: Tell the builder to skip the standard build/check phases,
  # as we don't have a setup.py or pyproject.toml file.
  format = "script";

  # Python dependencies for the script
  propagatedBuildInputs = [
    python3Packages.pygobject3
    gtk3
  ];

  # Your custom installPhase is used instead of a standard one.
  installPhase = ''
    runHook preInstall
    install -Dm755 ./window-search.py $out/bin/window-search
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/window-search \
      --prefix GI_TYPELIB_PATH : "${gtk3}/lib/girepository-1.0" \
      --prefix PATH : ${lib.makeBinPath [
      hyprland # for hyprctl
      wofi # for the menu
      gtk3 # for Gtk.IconTheme
    ]}
  '';

  meta = with lib; {
    description = "Python script to switch between Hyprland windows using wofi";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "window-search";
  };
}
