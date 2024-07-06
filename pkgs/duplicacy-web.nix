# from https://github.com/NixOS/nixpkgs/pull/311512
# TODO attempt to clean this up and submit a PR to nixpkgs (ask for permission from original author first)
#    would close https://github.com/NixOS/nixpkgs/issues/239435
{
  stdenv,
  fetchurl,
  lib,
}: let
  inherit (stdenv.hostPlatform) system;

  version = "1.8.1";
  # platforms-sets = {
  #   x86_64-linux = {
  #     url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_x64_${version}";
  #     hash = "sha256-XgyMlA7rN4YU6bXWP52/9K2LhEigjzgD2xQenGU6dn4=";
  #   };
  #   aarch64-linux = {
  #     url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_arm64_${version}";
  #     hash = "sha256-M2RluQKsP1002khAXwWcrTMeBu8sHgV8d9iYRMw3Zbc=";
  #   };
  #   armv5tel-linux = {
  #     url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_arm_${version}";
  #     hash = "sha256-O4CHtKiRTciqKehwCNOJciD8wP40cL95n+Qg/NhVSGQ=";
  #   };
  # };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "duplicacy-web";

    inherit version;

    src = fetchurl {
      url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_x64_${version}";
      hash = "sha256-XgyMlA7rN4YU6bXWP52/9K2LhEigjzgD2xQenGU6dn4=";
    };
    # src = fetchurl (finalAttrs.platforms-sets.${system} or throw "Unsupported system: ${system}");
    # src = fetchurl {
    #   url = platforms.${system}.url or throw "Unsupported system: ${system}";
    #   sha256 = platforms.${system}.hash or throw "Unsupported system: ${system}";
    # };
    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/duplicacy-web
      chmod +x $out/bin/duplicacy-web
    '';

    meta = {
      homepage = "https://duplicacy.com";
      description = "A new generation cloud backup tool with web-based GUI";
      # platforms = lib.attrNames platforms-sets;
      # license = licenses.unfree;
      maintainers = with lib.maintainers; [DogeRam1500];
      downloadPage = "https://duplicacy.com/download.html";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  })
