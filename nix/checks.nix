{ pkgs, repoRoot, project, aikenPkg ? null }:
let
  offchainTests = project.packages.offchain-tests;
  budgetCases = project.packages.budget-cases;

  offchainFormat = pkgs.writeShellApplication {
    name = "offchain-format";
    runtimeInputs = [ pkgs.findutils pkgs.fourmolu ];
    excludeShellChecks = [ "SC2046" ];
    text = ''
      cd ${repoRoot}/offchain
      fourmolu -m check $(find src test -name '*.hs')
    '';
  };

  offchainLint = pkgs.writeShellApplication {
    name = "offchain-lint";
    runtimeInputs = [ pkgs.hlint ];
    text = ''
      cd ${repoRoot}/offchain
      hlint src test
    '';
  };

  onchain = pkgs.writeShellApplication {
    name = "onchain-gate";
    runtimeInputs = pkgs.lib.optionals (aikenPkg != null) [ aikenPkg ];
    text = ''
      cd ${repoRoot}/onchain
      aiken build
      aiken check
      aiken fmt --check
    '';
  };

  onchainBlueprint = pkgs.runCommand "cardano-bbs-onchain-blueprint" {} ''
    mkdir -p $out
    cp ${repoRoot}/onchain/plutus.json $out/plutus.json
  '';
in
{
  offchain-library = project.packages.offchain-library;
  offchain-tests = offchainTests;
  offchain-format = offchainFormat;
  offchain-lint = offchainLint;
  onchain = onchain;
  budget-cases = budgetCases;
  onchainBlueprint = onchainBlueprint;
}
