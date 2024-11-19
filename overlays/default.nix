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

  # modifications that only are applied to system config, not home config
  system-modifications = final: prev: {
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
    # TODO blur the image first
    # TODO fix for gnome 47
    # gnome-shell = prev.gnome-shell.overrideAttrs (old: {
    #   patches =
    #     (old.patches or [])
    #     ++ [
    #       ./gdm-background.patch
    #     ];
    # });
  };
}
