{
  description = "BBS+ anonymous credentials for Cardano";

  nixConfig = {
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys =
      [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
  };

  inputs = {
    haskellNix.url =
      "github:input-output-hk/haskell.nix/baa6a549ce876e9c44c494a12116f178f1becbe6";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    aiken.url = "github:aiken-lang/aiken";
    iohkNix = {
      url =
        "github:input-output-hk/iohk-nix/0ce7cc21b9a4cfde41871ef486d01a8fafbf9627";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    CHaP = {
      url =
        "github:intersectmbo/cardano-haskell-packages/a46182e9c039737bf43cdb5286df49bbe0edf6fb";
      flake = false;
    };
    cardano-node = {
      url = "github:IntersectMBO/cardano-node/10.5.4";
    };
  };

  outputs = { self, nixpkgs, flake-utils, aiken, iohkNix, haskellNix, CHaP, cardano-node }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            iohkNix.overlays.crypto
            haskellNix.overlay
            iohkNix.overlays.haskell-nix-crypto
            iohkNix.overlays.cardano-lib
            (final: prev: {
              zkryptium_ffi = prev.callPackage ./nix/zkryptium-ffi.nix { };
            })
          ];
        };

        repoRoot = ./.;
        indexState = "2025-12-07T00:00:00Z";
        aikenPkg = aiken.packages.${system}.aiken or null;
        cardanoNodePkg = cardano-node.packages.${system}.cardano-node or null;
        project = import ./nix/project.nix {
          inherit pkgs CHaP aikenPkg cardanoNodePkg indexState repoRoot;
        };
        checks = import ./nix/checks.nix {
          inherit pkgs repoRoot project aikenPkg;
        };
      in
      {
        packages = project.packages // {
          onchain-blueprint = checks.onchainBlueprint;
          default = project.packages.offchain-library;
        };

        inherit checks;

        apps = import ./nix/apps.nix {
          inherit pkgs checks repoRoot aikenPkg cardanoNodePkg;
        };

        inherit (project) devShells;
      });
}
