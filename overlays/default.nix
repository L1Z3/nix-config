# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    notion-app-enhanced = prev.notion-app-enhanced.overrideAttrs (oldAttrs: rec {
      pname = oldAttrs.pname;
      version = oldAttrs.version;
      src = prev.fetchurl {
        url = "https://github.com/notion-enhancer/notion-repackaged/releases/download/v${version}/Notion-Enhanced-${version}.AppImage";
        sha256 = "sha256-SqeMnoMzxxaViJ3NPccj3kyMc1xvXWULM6hQIDZySWY=";
      };
      appimageContents =
        (prev.pkgs.appimageTools.extract {inherit pname version src;})
        .overrideAttrs (oA: {
          buildCommand = ''
            ${oA.buildCommand}

            ${prev.pkgs.asar}/bin/asar extract $out/resources/app.asar $out/app.unpacked
            ${prev.pkgs.dos2unix}/bin/dos2unix $out/app.unpacked/renderer/preload.js
            patch $out/app.unpacked/renderer/preload.js ${./notion-fix.patch}
            ${prev.pkgs.dos2unix}/bin/unix2dos $out/app.unpacked/renderer/preload.js
            rm $out/resources/app.asar
            ${prev.pkgs.asar}/bin/asar pack $out/app.unpacked $out/resources/app.asar
          '';
        });
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
