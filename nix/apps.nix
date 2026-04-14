{ pkgs, checks, repoRoot, aikenPkg ? null, cardanoNodePkg ? null }:
let
  mkRepoApp = name: runtimeInputs: text:
    {
      type = "app";
      program = pkgs.lib.getExe (pkgs.writeShellApplication {
        inherit name runtimeInputs text;
        excludeShellChecks = [ "SC2046" ];
      });
    };
in
{
  offchain-tests = mkRepoApp "offchain-tests-app" (
    (pkgs.lib.optionals (aikenPkg != null) [ aikenPkg ])
    ++ (pkgs.lib.optionals (cardanoNodePkg != null) [ cardanoNodePkg ])
  ) ''
    repo_path="''${CARDANO_BBS_REPO_ROOT:-${repoRoot}}"
    export E2E_GENESIS_DIR="/code/cardano-node-clients/e2e-test/genesis"
    cd "$repo_path/offchain"
    exec ${checks.offchain-tests}/bin/unit-tests "$@"
  '';

  offchain-format = mkRepoApp "offchain-format-app" [ pkgs.findutils pkgs.fourmolu ] ''
    repo_path="''${CARDANO_BBS_REPO_ROOT:-${repoRoot}}"
    cd "$repo_path/offchain"
    exec fourmolu -m check $(find src test -name '*.hs')
  '';

  offchain-lint = mkRepoApp "offchain-lint-app" [ pkgs.hlint ] ''
    repo_path="''${CARDANO_BBS_REPO_ROOT:-${repoRoot}}"
    cd "$repo_path/offchain"
    exec hlint src test
  '';

  onchain = mkRepoApp "onchain-app" (
    [ pkgs.jq ]
    ++ (pkgs.lib.optionals (aikenPkg != null) [ aikenPkg ])
  ) ''
    repo_path="''${CARDANO_BBS_REPO_ROOT:-${repoRoot}}"
    cd "$repo_path/onchain"
    aiken build
    cd "$repo_path"
    ./scripts/check-budget-matrix.sh
    cd "$repo_path/onchain"
    exec aiken fmt --check
  '';

  "budget-cases" = mkRepoApp "budget-cases-app" [ ] ''
    repo_path="''${CARDANO_BBS_REPO_ROOT:-${repoRoot}}"
    cd "$repo_path/offchain"
    exec ${checks.budget-cases}/bin/budget-cases "$@"
  '';
}
