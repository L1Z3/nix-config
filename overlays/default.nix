# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # TODO find a way to move this to gnome-settings.nix
    # TODO test and enable this
    # from https://discourse.nixos.org/t/gdm-background-image-and-theme/12632/10
    # gnome = prev.gnome.overrideScope (selfg: superg: {
    #       gnome-shell = superg.gnome-shell.overrideAttrs (old: {
    #         patches = (old.patches or []) ++ [
    #           (let
    #             # bg = pkgs.fetchurl {
    #             #   url = "https://orig00.deviantart.net/0054/f/2015/129/b/9/reflection_by_yuumei-d8sqdu2.jpg";
    #             #   sha256 = "0f0vlmdj5wcsn20qg79ir5cmpmz5pysypw6a711dbaz2r9x1c79l";
    #             # };
    #           in prev.pkgs.writeText "bg.patch" ''
    #             --- a/data/theme/gnome-shell-sass/widgets/_login-lock.scss
    #             +++ b/data/theme/gnome-shell-sass/widgets/_login-lock.scss
    #             @@ -15,4 +15,5 @@ $_gdm_dialog_width: 23em;
    #              /* Login Dialog */
    #              .login-dialog {
    #                background-color: $_gdm_bg;
    #             +  background-image: url('file://${prev.pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/blobs-l.svg');
    #              }
    #           '')
    #         ];
    #       });
    #     });

    # TODO clean this up once i figure out notion app stuff
    # notion-app-enhanced = prev.notion-app-enhanced.overrideAttrs (oldAttrs: rec {
    #   # pname = oldAttrs.pname;
    #   # version = oldAttrs.version;
    #   # src = prev.fetchurl {
    #   #   url = "https://github.com/notion-enhancer/notion-repackaged/releases/download/v${version}/Notion-Enhanced-${version}.AppImage";
    #   #   sha256 = "sha256-SqeMnoMzxxaViJ3NPccj3kyMc1xvXWULM6hQIDZySWY=";
    #   # };
    #   appimageContents =
    #     oldAttrs
    #     .appimageContents
    #     .overrideAttrs (oA: {
    #       buildCommand = ''
    #         ${oA.buildCommand}

    #         ${prev.pkgs.asar}/bin/asar extract $out/resources/app.asar $out/app.unpacked
    #         ${prev.pkgs.dos2unix}/bin/dos2unix $out/app.unpacked/renderer/preload.js
    #         patch $out/app.unpacked/renderer/preload.js ${./notion-fix.patch}
    #         ${prev.pkgs.dos2unix}/bin/unix2dos $out/app.unpacked/renderer/preload.js
    #         rm $out/resources/app.asar
    #         ${prev.pkgs.asar}/bin/asar pack $out/app.unpacked $out/resources/app.asar
    #       '';
    #     });
    # });
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
