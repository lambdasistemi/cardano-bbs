{ pkgs, repoRoot, runtimeInputs, ldLibraryPath, pkgConfigPath, includePath }:
let
  mkRepoCheck = name: text:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      excludeShellChecks = [ "SC2046" ];
      text = ''
        repo_path="''${CARDANO_BBS_REPO_ROOT:-$PWD}"
        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        export LD_LIBRARY_PATH=${ldLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
        export LIBRARY_PATH=${ldLibraryPath}''${LIBRARY_PATH:+:$LIBRARY_PATH}
        export PKG_CONFIG_PATH=${pkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
        export C_INCLUDE_PATH=${includePath}''${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}
        cd "$repo_path"
        ${text}
      '';
    };

  offchain = mkRepoCheck "offchain-gate" ''
    just build-offchain
    just test-offchain
    cd offchain
    fourmolu -m check $(find src test -name '*.hs')
    hlint src test
  '';

  onchain = mkRepoCheck "onchain-gate" ''
    just build-onchain
    just test-onchain
    cd onchain
    aiken fmt --check
  '';

  ci = mkRepoCheck "ci-gate" ''
    ${pkgs.lib.getExe offchain}
    ${pkgs.lib.getExe onchain}
  '';

  budgetCases = mkRepoCheck "budget-cases" ''
    cd offchain/cbits/zkryptium-ffi
    cargo build --release
    cd "$repo_path/offchain"
    cabal update
    LD_LIBRARY_PATH="$PWD/cbits/zkryptium-ffi/target/release''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      cabal run budget-cases --extra-lib-dirs="$PWD/cbits/zkryptium-ffi/target/release"
  '';

  onchainBlueprint = pkgs.runCommand "cardano-bbs-onchain-blueprint" {} ''
    mkdir -p $out
    cp ${repoRoot}/onchain/plutus.json $out/plutus.json
  '';
in
{
  inherit offchain onchain ci budgetCases onchainBlueprint;
}
