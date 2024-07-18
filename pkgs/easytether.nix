# TODO
#   debug: fix _easytether: unknown (maybe need to add udev or systemd stuff)
#   if want to upstream:
#      add other OSes/architectures (and abstract across arch/OS)
#      add option to enable service
{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  openssl_1_1,
  bluez,
}:
stdenv.mkDerivation rec {
  pname = "easytether";
  version = "0.8.9";

  # src = fetchzip {
  #   url = "http://www.mobile-stream.com/beta/arch/${pname}-${version}-1-x86_64.pkg.tar.xz";
  #   sha256 = "sha256-3dL5tNxa1hou0SunXOcf0Wkh//hNfzbuI2Dnmk/ibns=";
  #   stripRoot = false;
  # };

  src = fetchurl {
    url = "http://www.mobile-stream.com/beta/ubuntu/20.04/easytether_0.8.9_amd64.deb";
    sha256 = "sha256-QCvPqtQeita845BGZ4YSw9QhAMxeeXpJJglJhTz9wC4=";
  };

  unpackPhase = ''
    dpkg-deb -R $src .
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
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

    # cp -r usr/lib/* "$out/lib"

    runHook postInstall
  '';

  # Also expose the udev rules here, so it can be used as:
  #   services.udev.packages = [ pkgs.easytether ];
  # to allow non-root users to use the device.

  extraInstallCommands = ''
    install -m 444 \
      -D usr/lib/99-easytether-usb.rules \
      -t $out/lib/udev/rules.d
  '';

  meta = with lib; {
    description = "Program to share internet connection from Android to PC";
    homepage = "http://www.mobile-stream.com/easytether";
    # license = with licenses; [ ... ];
    # platforms = platforms.linux;
    # maintainers = with maintainers; [ ... ];
  };
}
