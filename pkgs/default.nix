# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  nbt-explorer = pkgs.callPackage ./nbt-explorer.nix {};
  etcher = pkgs.callPackage ./etcher.nix {};
  notion-app-enhanced = pkgs.callPackage ./notion-app-enhanced {};
  awatcher = pkgs.callPackage ./awatcher {};
  olympus = pkgs.callPackage ./olympus/package.nix {};
  duplicacy-web = pkgs.callPackage ./duplicacy-web.nix {};
  duplicacy-mount = pkgs.callPackage ./duplicacy-mount.nix {};
  yuzu = pkgs.callPackage ./yuzu.nix {};
  citra-qt = pkgs.callPackage ./citra-qt.nix {};
  easytether = pkgs.callPackage ./easytether.nix {};
  davinci-resolve-studio-patched = pkgs.callPackage ./davinci-resolve-patched.nix {};
  piavpn = pkgs.callPackage ./piavpn.nix {};
  binaryninja = pkgs.callPackage ./binaryninja.nix {};
  fastx-client = pkgs.callPackage ./fastx-client.nix {};
  qtcreator-with-deps = pkgs.callPackage ./qtcreator-with-deps.nix {};
  godot-4-mono-bin = pkgs.callPackage ./godot-4-mono-bin.nix {};
  audiorelay = pkgs.callPackage ./audiorelay.nix {};
  warpinator-fixed = pkgs.callPackage ./warpinator-fixed.nix {};
}
