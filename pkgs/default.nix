# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  nbt-explorer = pkgs.callPackage ./nbt-explorer.nix {};
  etcher = pkgs.callPackage ./etcher.nix {};
  notion-app-enhanced = pkgs.callPackage ./notion-app-enhanced {};
  awatcher = pkgs.callPackage ./awatcher {};
}
