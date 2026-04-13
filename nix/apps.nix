{ pkgs, checks }:
builtins.mapAttrs
  (_: check: {
    type = "app";
    program = pkgs.lib.getExe check;
  })
  {
    inherit (checks) offchain onchain;
    "budget-cases" = checks.budgetCases;
  }
