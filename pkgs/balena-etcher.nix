{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  makeDesktopItem,
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

  iconSrc = fetchFromGitHub {
    owner = "balena-io";
    repo = "etcher";
    rev = "c748c2a9c022d1d61b44e70202d073b00cdbd08c";
    sparseCheckout = ["assets/icon.png"];
    hash = "sha256-gTl4+MUB/W6ZiwEmdEdoqJYn+dYZx8ColRXs670wdbk=";
  };

  desktopItem = makeDesktopItem {
    categories = ["Utility"];
    genericName = "OS image flasher";
    desktopName = "balenaEtcher";
    name = pname;
    icon = pname;
    exec = meta.mainProgram;
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

    install -D $iconSrc/assets/icon.png $out/share/icons/${pname}.png
    install -D -t $out/share/applications ${desktopItem}/share/applications/*

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
