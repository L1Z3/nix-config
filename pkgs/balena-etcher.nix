{
  lib,
  stdenv,
  fetchurl,
  bash,
  asar,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  udev,
  electron,
}:
stdenv.mkDerivation rec {
  pname = "etcher";
  version = "1.19.21";

  src = fetchurl {
    url = "https://github.com/balena-io/etcher/releases/download/v${version}/balena-etcher_${version}_amd64.deb";
    hash = "sha256-wXdtKFeHKxGT8h+i3RrLNNBUYsVQ0hDabhzysue7be0=";
  };

  nativeBuildInputs = [
    asar
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    udev
  ];

  dontConfigure = true;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/${pname}

    cp -a usr/share/* $out/share
    cp -a usr/lib/balena-etcher/{locales,resources} $out/share/${pname}

    asar extract $out/share/${pname}/resources/app.asar app

    substituteInPlace app/.webpack/renderer/main_window/index.js \
      --replace '/usr/bin/pkexec' '/usr/bin/pkexec", "/run/wrappers/bin/pkexec' \
      --replace '/bin/bash' '${bash}/bin/bash' \
      --replace 'process.resourcesPath' "'$out/share/${pname}/resources'"

    substituteInPlace app/.webpack/main/index.js \
      --replace 'process.resourcesPath' "'$out/share/${pname}/resources'"

    asar pack --unpack='{*.node,*.ftz,rect-overlay}' app $out/share/${pname}/resources/app.asar

    makeWrapper ${electron}/bin/electron $out/bin/${pname} \
      --add-flags $out/share/${pname}/resources/app.asar

    runHook postInstall
  '';

  meta = with lib; {
    description = "Flash OS images to SD cards and USB drives, safely and easily";
    homepage = "https://etcher.io/";
    license = licenses.asl20;
    mainProgram = "etcher";
    maintainers = with maintainers; [wegank];
    platforms = ["x86_64-linux"];
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
}
