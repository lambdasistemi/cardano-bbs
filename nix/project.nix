{ pkgs, CHaP, aikenPkg ? null, cardanoNodePkg ? null, indexState, repoRoot }:

let
  indexTool = { index-state = indexState; };

  fixLibs = { lib, pkgs, ... }: {
    reinstallableLibGhc = true;

    packages.cardano-crypto-praos.components.library.pkgconfig =
      lib.mkForce [ [ pkgs.libsodium-vrf ] ];
    packages.cardano-crypto-class.components.library.pkgconfig =
      lib.mkForce [ [ pkgs.libsodium-vrf pkgs.secp256k1 pkgs.libblst ] ];

  };

  shell = { pkgs, ... }: {
    tools = {
      cabal = indexTool;
      cabal-fmt = indexTool;
      haskell-language-server = indexTool;
      hoogle = indexTool;
      fourmolu = indexTool;
      hlint = indexTool;
    };
    withHoogle = true;
    buildInputs = [
      pkgs.just
      pkgs.curl
      pkgs.cacert
      pkgs.pkg-config
      pkgs.cargo
      pkgs.rustc
      pkgs.rustfmt
    ]
    ++ pkgs.lib.optionals (aikenPkg != null) [ aikenPkg ]
    ++ pkgs.lib.optionals (cardanoNodePkg != null) [ cardanoNodePkg ];
    shellHook = ''
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      echo "cardano-bbs dev shell"
    '';
  };

  project = pkgs.haskell-nix.cabalProject' {
    name = "cardano-bbs";
    src = pkgs.haskell-nix.cleanSourceHaskell {
      name = "cardano-bbs-offchain";
      src = repoRoot + "/offchain";
    };
    cabalProject = builtins.readFile (repoRoot + "/offchain/cabal.project");
    compiler-nix-name = "ghc984";
    shell = shell { inherit pkgs; };
    modules = [ fixLibs ];
    inputMap = {
      "https://chap.intersectmbo.org/" = CHaP;
    };
  };
in
{
  inherit project;

  devShells.default = project.shell;

  packages = {
    zkryptium-ffi = pkgs.zkryptium_ffi;
    offchain-library =
      project.hsPkgs.cardano-bbs.components.library;
    offchain-tests =
      project.hsPkgs.cardano-bbs.components.tests.unit-tests;
    budget-cases =
      project.hsPkgs.cardano-bbs.components.exes.budget-cases;
  };
}
