{ pkgs, checks }:
builtins.mapAttrs
  (_: check: {
    type = "app";
    program = pkgs.lib.getExe check;
  })
  {
    inherit (checks) offchain onchain ci;
    "budget-cases" = checks.budgetCases;
  }
