# based on https://github.com/MonochromeBird/system-constitution/blob/a69ee24a46e8942892a03906c7b5e7f9d10e78c6/system/modules/programming/godot-mono-derivation.nix
# and https://github.com/chaotic-cx/nyx/blob/1b86b304c8eb1437d9337a760e7f930826fc4d6d/pkgs/godot_4-mono/default.nix
{
  pkgs ? import <nixpkgs> {},
  version ? "4.3-stable",
  bin_name ? "godot-4-mono-bin",
  repo ? "godot",
  hash ? "sha256-L32cwE/E1aEAz6t3SlO0k/QQuKRt/8lJntfdCYVdGCE=",
}:
pkgs.stdenv.mkDerivation rec {
  release = "Godot_v${version}_mono_linux";
  bin = "${release}.x86_64";

  dirname = "${release}_x86_64";
  zipname = "${dirname}.zip";

  name = "Godot_${version}_mono";
  pname = bin_name;

  src = pkgs.fetchzip {
    url = "https://github.com/godotengine/${repo}/releases/download/${version}/${zipname}";
    hash = hash;
  };

  srcsource = pkgs.fetchFromGitHub {
    owner = "godotengine";
    repo = "godot";
    rev = "77dcf97d82cbfe4e4615475fa52ca03da645dbd8";
    hash = "sha256-v2lBD3GEL8CoIwBl3UoLam0dJxkLGX0oneH6DiWkEsM=";
  };

  nativeBuildInputs = with pkgs; [
    unzip

    pkg-config
    autoPatchelfHook
    installShellFiles
    python3
    speechd
    wayland-scanner
    makeWrapper
    mono
    dotnet-sdk_8
    dotnet-runtime_8
  ];

  runtimeDependencies = with pkgs; [
    vulkan-loader
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXinerama
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXfixes
    libxkbcommon
    alsa-lib
    mono
    wayland-scanner
    dotnet-sdk_8
    dotnet-runtime_8

    # optional
    libpulseaudio
    udev
    fontconfig
    fontconfig.lib
    speechd
    dbus
    dbus.lib
  ];

  phases = ["installPhase"];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp $src/${bin} $out/bin/godot4-mono
    cp -r $src/GodotSharp/ $out/bin/

    installManPage $srcsource/misc/dist/linux/godot.6

    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp $srcsource/misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/org.godotengine.Godot4-Mono.desktop"
    substituteInPlace "$out/share/applications/org.godotengine.Godot4-Mono.desktop" \
      --replace-quiet "Exec=godot" "Exec=$out/bin/godot4-mono" \
      --replace-quiet "Godot Engine" "Godot Engine ${version} (Mono, $(echo "single" | sed 's/.*/\u&/') Precision)"
    cp $srcsource/icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp $srcsource/icon.png "$out/share/icons/godot.png"

    wrapProgram $out/bin/godot4-mono \
      --set DOTNET_ROOT ${pkgs.dotnet-sdk_8} \
      --prefix PATH : "${pkgs.lib.makeBinPath [
      pkgs.dotnet-sdk_8
      pkgs.dotnet-runtime_8
      pkgs.mono
      pkgs.msbuild
    ]}" \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeDependencies}"
    runHook postInstall
  '';
}
