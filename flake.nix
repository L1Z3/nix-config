{
  description = "main nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    # to maintain compatibility with old unstable overlay
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-krisp-discord-fix.url = "github:samschlegel/nixpkgs/samschlegel/use-fhsenv-for-discord-linux";

    # local dev fork of nixpkgs
    # nixpkgs-dev.url = "/home/liz/projects/nixpkgs-fork-dev";

    # master... just in case i really really want a package that isn't in unstable yet
    # comment out if not needed, other things should adjust
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # declarative flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # local flake that contains info that I don't want publicized (not passwords, etc, just personal info)
    secrets.url = "/home/liz/nix/secrets";

    # more vscode extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # pre-generated database for nix-index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # hyprland = {
    #   url = "github:hyprwm/Hyprland?ref=v0.50.1";
    #   # inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins?ref=v0.50.0";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hypr-dynamic-cursors = {
    #   url = "github:VirtCode/hypr-dynamic-cursors?ref=d6eb0b798c9b07f7f866647c8eb1d75a930501be";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hyprsplit = {
    #   url = "github:shezdy/hyprsplit";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hyprland-qtutils = {
    #   url = "github:hyprwm/hyprland-qtutils";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hyprland-qt-support = {
    #   url = "github:hyprwm/hyprland-qt-support";
    #   inputs.hyprland.follows = "hyprland";
    # };

    catppuccin.url = "github:catppuccin/nix";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  };

  # enable the nix community cache, unfree cache
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
    ];
    extra-trusted-substituters = [
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      envy = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        # > Our main nixos configuration file <
        modules = [./nixos/configuration.nix];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "liz@envy" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        # > Our main home-manager configuration file <
        modules = [./home-manager/home.nix];
      };
    };
  };
}
