{
  description = "BBS+ anonymous credentials for Cardano";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    aiken.url = "github:aiken-lang/aiken";
    iohkNix = {
      url = "github:input-output-hk/iohk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, aiken, iohkNix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            iohkNix.overlays.crypto
            iohkNix.overlays.cardano-lib
          ];
        };
        aikenPkg = aiken.packages.${system}.aiken or null;
        repoRoot = ./.;
        ldLibraryPath = pkgs.lib.makeLibraryPath [
          pkgs.libsodium-vrf
          pkgs.secp256k1
          pkgs.blst
          pkgs.zlib
        ];
        pkgConfigPath = pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
          pkgs.libsodium-vrf
          pkgs.secp256k1
          pkgs.blst
          pkgs.lmdb
          pkgs.zlib
        ];
        includePath = pkgs.lib.makeSearchPathOutput "dev" "include" [
          pkgs.libsodium-vrf
          pkgs.secp256k1
          pkgs.blst
          pkgs.lmdb
          pkgs.zlib
        ];
        runtimeInputs = with pkgs;
          [
            haskell.compiler.ghc984
            cabal-install
            fourmolu
            hlint
            pkg-config
            stdenv.cc
            curl
            cacert
            libsodium-vrf
            secp256k1
            blst
            lmdb
            zlib
            cargo
            rustc
            rustfmt
            just
          ]
          ++ pkgs.lib.optionals (aikenPkg != null) [ aikenPkg ];
        checks = import ./nix/checks.nix {
          inherit pkgs repoRoot runtimeInputs ldLibraryPath pkgConfigPath
            includePath;
        };
      in
      {
        packages = {
          onchain-blueprint = checks.onchainBlueprint;
          budget-cases = checks.budgetCases;
          default = checks.onchainBlueprint;
        };

        inherit checks;

        apps = import ./nix/apps.nix {
          inherit pkgs checks;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = runtimeInputs
            ++ [
              pkgs.haskell-language-server
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ];

          shellHook = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export LD_LIBRARY_PATH="${ldLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            echo "cardano-bbs dev shell"
            echo "  ghc:    $(ghc --version)"
            echo "  cabal:  $(cabal --version | head -1)"
            echo "  cargo:  $(cargo --version)"
          '';
        };
      });
}
