{
  fetchzip,
  fetchFromGitHub,
  lib,
  makeDesktopItem,
  makeWrapper,
  nix-update-script,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "balena-etcher";
  version = "1.19.21";
  #
  src = fetchzip {
    url = "https://github.com/balena-io/etcher/releases/download/v${version}/balenaEtcher-linux-x64-${version}.zip";
    hash = "sha256-bjgNtiLZNIOAcelLAeS05L7hyDq91RXhUIED4Bwww+E=";
    stripRoot = true;
  };

  iconSrc = fetchFromGitHub {
    owner = "balena-io";
    repo = "etcher";
    rev = "c748c2a9c022d1d61b44e70202d073b00cdbd08c";
    sparseCheckout = ["assets/icon.png"];
    hash = "sha256-FpG37FImEioHztv8aBOOz6hoJjs+glG4MFmM1DPGyUs=";
  };

  desktopItem = makeDesktopItem {
    categories = ["Utility"];
    genericName = "OS image flasher";
    desktopName = "balenaEtcher";
    name = pname;
    icon = pname;
    exec = meta.mainProgram;
  };

  phases = ["installPhase" "patchPhase"];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/lib
    cp --target-directory $out/lib \
      $src/NBTExplorer.exe \
      $src/NBTModel.dll \
      $src/Substrate.dll

    makeWrapper "${mono}/bin/mono" $out/bin/${pname} \
      --add-flags "$out/lib/NBTExplorer.exe" \
      --suffix LD_LIBRARY_PATH : ${gtk2-x11}/lib

    install -D $iconSrc/assets/icon.png $out/share/icons/${pname}.png
    install -D -t $out/share/applications ${desktopItem}/share/applications/*
  '';

  # FIXME: “replace() argument 1 must be str, not None” at nix_update/update.py:39
  # passthru.updateScript = nix-update-script {
  #   extraArgs = [ "--version-regex" "(.*)-win" ];
  # };

  meta = {
    description = "Flash OS images to SD cards & USB drives, safely and easily.";
    homepage = "https://github.com/jaquadro/NBTExplorer";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
