{pkgs, ...}:
# A function to wrap a package with a desktop icon and .desktop file.
#
# Arguments:
# - name: Name for the wrapped package (also used as desktop filename and icon name).
# - iconUrl: URL of the icon to fetch.
# - iconSha256: sha256 of the fetched icon file. Use `nix-prefetch-url` to obtain this.
# - desktopFileText: The contents of the .desktop file.
# - targetPackage: The package you want to wrap (e.g., pkgs.unstable.mcaselector).
#
# Example usage:
#
# let
#   desktopWrapper = import ./desktop-wrapper.nix { inherit pkgs; };
# in
# desktopWrapper.mkDesktopWrappedPackage {
#   name = "mcaselector";
#   iconUrl = "https://raw.githubusercontent.com/Querz/mcaselector/cbeff376929070f27514113943a34349fdc3cc43/installer/img/small.bmp";
#   iconSha256 = "<sha256-here>";
#   desktopFileText = ''
#     [Desktop Entry]
#     Type=Application
#     Name=MCA Selector
#     Exec=${pkgs.unstable.mcaselector}/bin/mcaselector
#     Icon=mcaselector
#     Terminal=false
#     Categories=Game;
#   '';
#   targetPackage = pkgs.unstable.mcaselector;
# }
let
  mkDesktopWrappedPackage = {
    name,
    iconUrl,
    iconSha256,
    desktopFileText,
    targetPackage,
  }: let
    # Fetch the original icon
    iconOriginal = pkgs.fetchurl {
      url = iconUrl;
      sha256 = iconSha256;
    };

    # Convert the icon to PNG using ImageMagick for better compatibility
    iconPng = pkgs.runCommand "${name}-icon" {buildInputs = [pkgs.imagemagick];} ''
      mkdir -p $out
      convert ${iconOriginal} $out/icon.png
    '';

    # Create a derivation that installs the desktop file and the icon
    desktopOutput = pkgs.runCommand "${name}-desktop" {} ''
            mkdir -p $out/share/applications
            mkdir -p $out/share/pixmaps

            # Install the icon
            cp ${iconPng}/icon.png $out/share/pixmaps/${name}.png

            # Write the .desktop file
            cat > $out/share/applications/${name}.desktop <<EOF
      ${desktopFileText}
      EOF
    '';
  in
    pkgs.symlinkJoin {
      inherit name;
      paths = [
        targetPackage
        desktopOutput
      ];
    };
in {
  inherit mkDesktopWrappedPackage;
}
