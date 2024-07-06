# patched notion enchanced package to fix not booting on linux, see https://github.com/notion-enhancer/notion-enhancer/issues/812
{
  appimageTools,
  lib,
  fetchurl,
  asar,
}: let
  pname = "notion-app-enhanced";
  version = "2.0.18-1";

  src = fetchurl {
    url = "https://github.com/notion-enhancer/notion-repackaged/releases/download/v${version}/Notion-Enhanced-${version}.AppImage";
    sha256 = "sha256-SqeMnoMzxxaViJ3NPccj3kyMc1xvXWULM6hQIDZySWY=";
  };

  polyfill-patch = "./polyfill.js";

  appimageContents = (appimageTools.extract {inherit pname version src;}).overrideAttrs (oA: {
    buildCommand = ''
      ${oA.buildCommand}

      ${asar}/bin/asar extract $out/resources/app.asar app
      sed -e '/\"use strict\";/r${polyfill-patch}' app/renderer/preload.js > app/renderer/preload.js
      ${asar}/bin/asar pack app $out/resources/app.asar
    '';
  });
in
  appimageTools.wrapType2 {
    inherit pname version src;
    
    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = with lib; {
      description = "Notion Desktop builds with Notion Enhancer for Windows, MacOS and Linux";
      homepage = "https://github.com/notion-enhancer/desktop";
      license = licenses.unfree;
      maintainers = with maintainers; [sei40kr];
      platforms = ["x86_64-linux"];
      mainProgram = "notion-app-enhanced";
    };
  }