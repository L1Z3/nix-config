# TODO
#   debug: fix _easytether: unknown (maybe need to add udev or systemd stuff)
#   if want to upstream:
#      add other OSes/architectures (and abstract across arch/OS)
#      add option to enable service
{
  stdenv,
  lib,
  fetchzip,
  autoPatchelfHook,
  openssl_1_1,
  bluez,
}:
stdenv.mkDerivation rec {
  pname = "easytether";
  version = "0.8.9";

  src = fetchzip {
    url = "http://www.mobile-stream.com/beta/arch/${pname}-${version}-1-x86_64.pkg.tar.xz";
    sha256 = "sha256-3dL5tNxa1hou0SunXOcf0Wkh//hNfzbuI2Dnmk/ibns=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    openssl_1_1
    bluez
  ];

  runtimeInputs = [openssl_1_1];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    mkdir -p "$out/lib"
    install -m755 -D usr/bin/${pname}-usb $out/bin/${pname}-usb
    install -m755 -D usr/bin/${pname}-bluetooth $out/bin/${pname}-bluetooth
    install -m755 -D usr/bin/${pname}-local $out/bin/${pname}-local

    cp -r usr/lib/* "$out/lib"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Program to share internet connection from Android to PC";
    homepage = "http://www.mobile-stream.com/easytether";
    # license = with licenses; [ ... ];
    # platforms = platforms.linux;
    # maintainers = with maintainers; [ ... ];
  };
}
