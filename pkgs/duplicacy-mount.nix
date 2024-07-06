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
    rev = "v${version}-mount";
    hash = "sha256-2MXhTeBtW9ZOcAfjZCI9gdToCbYw3am5KlUHyP/EWH4=";
  };

  buildInputs = [fuse];

  modPostBuild = ''
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
