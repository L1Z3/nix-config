# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  nbt-explorer = pkgs.callPackage ./nbt-explorer.nix {};
  balena-etcher = pkgs.callPackage ./balena-etcher.nix {};
}
