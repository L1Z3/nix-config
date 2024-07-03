{
  description = "main nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # unstable Nixpkgs, to grab some unstable packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    overlays = {
      # This one brings our custom packages from the 'pkgs' directory
      # additions = final: _prev: import ../pkgs final.pkgs;

      # This one contains whatever you want to overlay
      # You can change versions, add patches, set compilation flags, anything really.
      # https://nixos.wiki/wiki/Overlays
      modifications = final: prev: {
        # example = prev.example.overrideAttrs (oldAttrs: rec {
        # ...
        # });
      };

      # When applied, the unstable nixpkgs set (declared in the flake inputs) will
      # be accessible through 'pkgs.unstable'
      unstable-packages = final: _prev: {
        unstable = import nixpkgs-unstable {
          # system = final.system;
          config.allowUnfree = true;
        };
      };
    };
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # FIXME replace with your hostname
      nixvm = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        # > Our main nixos configuration file <
        modules = [./nixos/configuration.nix];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # FIXME replace with your username@hostname
      "liz@nixvm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        # > Our main home-manager configuration file <
        modules = [./home-manager/home.nix];
      };
    };
  };
}
