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
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Haskell
            haskell.compiler.ghc984
            cabal-install
            haskell-language-server
            fourmolu
            hlint
            pkg-config
            libsodium-vrf
            secp256k1
            blst
            lmdb
            zlib

            # Rust (for zkryptium FFI)
            cargo
            rustc
            rustfmt
            just

            # Aiken
          ] ++ pkgs.lib.optionals (aikenPkg != null) [ aikenPkg ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ];

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.libsodium-vrf}/lib:${pkgs.secp256k1}/lib:${pkgs.blst}/lib:${pkgs.zlib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            echo "cardano-bbs dev shell"
            echo "  ghc:    $(ghc --version)"
            echo "  cabal:  $(cabal --version | head -1)"
            echo "  cargo:  $(cargo --version)"
          '';
        };
      });
}
