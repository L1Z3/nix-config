# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # same, but for master branch (if we enabled master in flake.nix)
  ${
    if inputs ? nixpkgs-master
    then "master-packages"
    else null
  } = final: _prev: {
    master = import inputs.nixpkgs-master {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # local repo dev packages (for my WIP changes)
  dev-packages = final: _prev: {
    dev = import inputs.nixpkgs-dev {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  qt652-commit-packages = final: _prev: {
    qt652-commit = import inputs.nixpkgs-qt652 {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # modifications that only are applied to system config, not home config
  system-modifications = final: prev: {
    # patch to prevent xdg-utils from override symlink, allowing mkOutOfStoreSymLink on mimeapps.list to work
    # TODO test this, and also attempt to only patch this for gnome to prevent having to recompile everything that depends on xdg-utils
    # TODO doesn't work, investigate why TODO maybe needs to be present in system and home
    # xdg-utils = prev.xdg-utils.overrideAttrs (oldAttrs: rec {
    #   patches =
    #     (oldAttrs.patches or []) ++ [./xdg-utils-dont-override-symlink.patch];
    # });
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # from https://github.com/nullbytepl/.nixconf/blob/f7f9fb6effc36bb2aac2f3e227ed4346037089ee/fragments/vmware.nix#L4
    # The vmware kernel module is broken on 6.9.1, so use a patched fork until nixpkgs is updated
    linuxPackages_latest = prev.linuxPackages_latest.extend (lpself: lpsuper: {
      vmware = prev.linuxPackages_latest.vmware.overrideAttrs (oldAttrs: {
        version = prev.linuxPackages_latest.vmware.version + "-FIXED";
        src = prev.pkgs.fetchFromGitHub {
          owner = "nan0desu";
          repo = "vmware-host-modules";
          rev = "d9f51eee7513715830ac214f1b25db79059f5270";
          sha256 = "sha256-63ZYa3X3fVpJQuHoBuqP5fs64COAgjJ9iG9LNkXPXfw=";
        };
      });
    });

    # don't spam logs with another window session manager logs
    gnomeExtensions =
      prev.gnomeExtensions
      // {
        unstable-another-window-session-manager-patched = final.unstable.gnomeExtensions.another-window-session-manager.overrideAttrs (oldAttrs: rec {
          patches =
            (oldAttrs.patches or []) ++ [./dont-spam-log.patch];
        });
      };

    # TODO fix
    # steam launch with steamos version (workaround to allow steam input in wayland native games) (Celeste with env SDL_VIDEODRIVER=wayland)
    # steam-original = prev.steam-original.overrideAttrs (oldAttrs: rec {
    #   postInstall =
    #     (oldAttrs.postInstall or "")
    #     + ''
    #       substituteInPlace $out/share/applications/steam.desktop \
    #         --replace "Exec=steam" "Exec=steam -steamos3"
    #     '';
    # });

    # TODO find a way to move this to gnome-settings.nix
    # from https://discourse.nixos.org/t/gdm-background-image-and-theme/12632/10
    # TODO this will break in a future gnome update
    # TODO blur the image first
    gnome = prev.gnome.overrideScope (selfg: superg: {
      gnome-shell = superg.gnome-shell.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            (let
              # bg = pkgs.fetchurl {
              #   url = "https://orig00.deviantart.net/0054/f/2015/129/b/9/reflection_by_yuumei-d8sqdu2.jpg";
              #   sha256 = "0f0vlmdj5wcsn20qg79ir5cmpmz5pysypw6a711dbaz2r9x1c79l";
              # };
            in
              prev.pkgs.writeText "bg.patch" ''
                --- a/data/theme/gnome-shell-sass/widgets/_login-lock.scss
                +++ b/data/theme/gnome-shell-sass/widgets/_login-lock.scss
                @@ -15,4 +15,5 @@ $_gdm_dialog_width: 23em;
                 /* Login Dialog */
                 .login-dialog {
                   background-color: $_gdm_bg;
                +  background-image: url('file://${prev.pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/blobs-l.svg');
                 }
              '')
          ];
      });
    });

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
}
