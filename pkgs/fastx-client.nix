# https://www.starnet.com/files/private/FastX3/FastX3-3.3.60.rhel7.x86_64.tar.gz
# TODO add desktop file
{
  stdenv,
  lib,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  # dependencies
  alsa-lib,
  e2fsprogs,
  expat,
  fontconfig,
  freetype,
  libGL,
  libgcc,
  libgpg-error,
  xorg,
  zlib,
}:
stdenv.mkDerivation {
  pname = "fastx-client";
  version = "3.3.60";

  buildInputs = [
    alsa-lib
    e2fsprogs
    expat
    fontconfig.lib
    freetype
    libGL
    libgcc.lib
    libgpg-error
    xorg.libX11
    xorg.libxcb
    zlib
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  src = fetchzip {
    url = "https://www.starnet.com/files/private/FastX3/FastX3-3.3.60.rhel7.x86_64.tar.gz";
    hash = "sha256-OYkdA1TPiM2mEvOOyfaVWQlsDW+TLx7fSaCoOaEier8=";
  };

  #buildPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/opt
    # temp hack
    rm -f qt.conf
    cp -r * $out/opt
    chmod +x $out/opt/FastX3
    makeWrapper $out/opt/FastX3 \
        $out/bin/FastX3
  '';

  meta = with lib; {
    description = "";
    homepage = "";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
