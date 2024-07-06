{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fuse,
}:
buildGoModule rec {
  pname = "duplicacy-mount";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "davidrios";
    repo = "duplicacy";
    # for some reason the release 3.0.1 source is not actually the latest commit even though the corresponding binary is
    # so just have the latest commit hash here
    rev = "3b2c5874e2fcfa557abf1b29c0d065b611a0dd05";
    hash = "sha256-2MXhTeBtW9ZOcAfjZCI9gdToCbYw3am5KlUHyP/EWH4=";
  };

  buildInputs = [fuse];

  postInstall = ''
    mv $out/bin/duplicacy $out/bin/${pname}
  '';

  vendorHash = "sha256-/mMLz7WOK+RJNNnSWnq1SvaCbD4K9tRPhCmsJS2kLRw=";

  doCheck = false;

  meta = with lib; {
    homepage = "https://duplicacy.com";
    description = "New generation cloud backup tool (patched for FUSE mount support)";
    platforms = platforms.linux;
    license = lib.licenses.unfree;
  };
}
