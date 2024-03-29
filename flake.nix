{
  description = "python 3.10";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/22.05";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix = {
      url =
        "github:DavHau/mach-nix?rev=913e6c16f986746ba5507878ef7ff992804d1fa8";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pypi-deps-db.follows = "pypi-deps-db";

    };
    pypi-deps-db = {
      url =
        "github:DavHau/pypi-deps-db?rev=dd28bbd22df34cb9d00c8e48b21e74001c16b19d";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.mach-nix.follows = "mach-nix";

    };

  };

  outputs =
    { self, nixpkgs, rust-overlay, flake-utils, mach-nix, pypi-deps-db, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        mach-nix_ = (import mach-nix) {
          inherit pkgs;
          pypiDataRev = pypi-deps-db.rev;
          pypiDataSha256 = pypi-deps-db.narHash;
          python = "python310";
        };
        python_requirements = ''
          jupyter
	        pandas
	        numpy
	        pybigwig
          dppd_plotnine
	        openpyxl
	        requests
	        requests[socks]
	        pip
	        marburg_biobank
	        bleach
          scipy
          pypipegraph
	        pypipegraph2
	        setuptools
          cython
          cython-package-example
          pytest
          pytest-cov
          pytest-mock
          vosk
          pynput
          pint
          twine
          fritzconnection
          black
          mypy
          flake8
          scikit-learn
          tensorflow
          jupyterlab
        '';
        mypython = mach-nix_.mkPython ({
          requirements = python_requirements;
          # no r packages here - we fix the rpy2 path below.
          providers = {
            #argon2-cffi = "nixpkgs"; 
            #argon2-cffi-bindings = "nixpkgs"; 
            polars = "sdist";
            librosa = "nixpkgs";
          };
          _."jupyter-core".postInstall = ''
            rm $out/lib/python*/site-packages/jupyter.py
            rm $out/lib/python*/site-packages/__pycache__/jupyter.cpython*.pyc
          '';

        });

      in with pkgs; {
        devShell = mkShell {
          buildInputs = [
            rust-bin.stable."1.59.0".default
            #(pkgs.python39.withPackages (pp: [ pp.maturin ]))
            pkgs.maturin
            bacon
            poppler_utils
            mypython
            julia_17-bin
          ];

          shellHook = ''
            # Tells pip to put packages into $PIP_PREFIX instead of the usual locations.
            # See https://pip.pypa.io/en/stable/user_guide/#environment-variables.
            export PIP_PREFIX=$(pwd)/_build/pip_packages
            export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
            export PATH="$PIP_PREFIX/bin:$PATH"
            unset SOURCE_DATE_EPOCH
          '';

        };

      });
}
