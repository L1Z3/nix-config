{pkgs, ...}: let
  python = pkgs.python3;
in
  python.pkgs.buildPythonApplication rec {
    pname = "beemod";
    version = "2.4.44.0";

    src = pkgs.fetchFromGitHub {
      owner = "BEEmod";
      repo = "BEE2.4";
      rev = "0928dace0d5d898096713a3548af77572aceb7b6";
      sha256 = "";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with pkgs; [
      python3Packages.pyinstaller
      tk
      tcl
      binutils
      # Add any tools needed during build, for example gdk-pixbuf if needed.
    ];

    # The runtime Python dependencies will be installed from requirements.txt.
    # If some are available in Nixpkgs, you can add them to propagatedBuildInputs for better integration.
    propagatedBuildInputs = with python.pkgs; [
      tkinter
      tkinter.src

      # Add packages if you know some from requirements.txt that are in nixpkgs
      # e.g. requests, PyInstaller is already in nativeBuildInputs
      # Otherwise, everything is installed by pip from requirements.txt below.
    ];

    # Create a dummy setup.py to allow pip to install requirements:
    # This also ensures we have a wheel environment to run pip installs inside Nix builds.
    # We'll rely on `pip install -r requirements.txt` manually in buildPhase.
    # buildPythonApplication expects something to install, so we give it a no-op package.
    # We'll run pip manually because there's no standard setup.py in BEE2.4.
    format = "other";
    prePatch = ''
          cat > setup.py <<EOF
      from setuptools import setup
      setup(name="${pname}", version="${version}", packages=[])
      EOF
    '';

    # We must disable geocable.py as per instructions:
    patchPhase = ''
      mv hammeraddons/transforms/geocable.py hammeraddons/transforms/geocable.py.disabled || true
    '';

    # The instructions say:
    # 1. `pip install -r requirements.txt`
    # 2. If on dev branch, `pip install -r dev-requirements.txt`
    # We'll do that in buildPhase after we get a virtualenv by default from buildPythonApplication.
    # We'll then run pyinstaller. According to instructions:
    #   cd src
    #   pyinstaller --distpath ../dist/64bit/ --workpath ../build_tmp compiler.spec
    #   pyinstaller --distpath ../dist/64bit/ --workpath ../build_tmp BEE2.spec
    buildPhase = ''
      # Install runtime dependencies:
      pip install --no-cache-dir -r requirements.txt

      # Build the executables:
      cd src
      pyinstaller --distpath ../dist/64bit/ --workpath ../build_tmp compiler.spec
      pyinstaller --distpath ../dist/64bit/ --workpath ../build_tmp BEE2.spec
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/beemod

      # Copy the built distribution:
      cp -r dist/64bit $out/share/beemod

      # The main executables should be in $out/share/beemod/64bit.
      # If the main launcher is named BEE2, link it:
      ln -s $out/share/beemod/64bit/BEE2 $out/bin/bee2
      ln -s $out/share/beemod/64bit/compiler $out/bin/bee2-compiler
    '';

    # No tests provided, skip check:
    doCheck = false;

    # If the application expects certain environment variables or GApps:
    # Add wrapper if needed. For now, we skip it.
    fixupPhase = ''
      # If needed, wrap the binaries:
      # wrapProgram $out/bin/bee2
    '';
  }
