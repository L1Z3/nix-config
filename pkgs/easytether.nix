# TODO
#   if want to upstream:
#      add other OSes/architectures (and abstract across arch/OS)
#      add option to enable service
{
  stdenv,
  lib,
  fetchzip,
  openssl_1_1,
}:
stdenv.mkDerivation rec {
  pname = "easytether";
  version = "0.8.9";

  src = fetchzip {
    url = "http://www.mobile-stream.com/beta/arch/${pname}-${version}-1-x86_64.pkg.tar.xz";
    sha256 = "sha256-3dL5tNxa1hou0SunXOcf0Wkh//hNfzbuI2Dnmk/ibns=";
    stripRoot = false;
  };

  runtimeInputs = [openssl_1_1];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    mkdir -p "$out/lib"
    cp usr/bin/* "$out/bin"
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
