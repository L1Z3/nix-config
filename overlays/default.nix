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
    # fix vmware download thing temporarily (https://github.com/NixOS/nixpkgs/issues/392841)
    vmware-workstation = let
      finalAttrs = final.vmware-workstation;
      version = "17.6.1";
      build = "24319023";
      baseUrl = "https://web.archive.org/web/20241105192443if_/https://softwareupdate.vmware.com/cds/vmw-desktop/ws/${version}/${build}/linux";
      vmware-unpack-env = prev.buildFHSEnv {
        pname = "vmware-unpack-env";
        inherit version;
        targetPkgs = pkgs: [pkgs.zlib];
      };
    in
      prev.vmware-workstation.overrideAttrs {
        src =
          prev.fetchzip {
            url = "${baseUrl}/core/VMware-Workstation-${version}-${build}.x86_64.bundle.tar";
            hash = "sha256-VzfiIawBDz0f1w3eynivW41Pn4SqvYf/8o9q14hln4s=";
            stripRoot = false;
          }
          + "/VMware-Workstation-${version}-${build}.x86_64.bundle";
        unpackPhase = ''
          ${vmware-unpack-env}/bin/vmware-unpack-env -c "sh ${finalAttrs.src} --extract unpacked"
        '';
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
