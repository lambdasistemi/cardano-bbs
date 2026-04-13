# cardano-bbs

BBS+ anonymous credentials for Cardano — Haskell off-chain library + Aiken on-chain verifier.

## Status

Early development.

## Structure

- `offchain/` — Haskell library: BBS+ credential issuance, proof derivation, serialization
- `onchain/` — Aiken validators: BBS+ proof-of-knowledge verification using CIP-0381 BLS12-381 built-ins

## Delivery Surface

The flake now separates development, delivery, and verification:

- `devShells.default`
  - local development environment
- `packages.onchain-blueprint`
  - builds the deployable validator blueprint from [onchain/plutus.json](/code/cardano-bbs-verify/onchain/plutus.json)
- `packages.budget-cases`
  - runnable budget measurement tool from [offchain/app/BudgetCases.hs](/code/cardano-bbs-verify/offchain/app/BudgetCases.hs)
- `checks.offchain`
  - off-chain build, tests, format, and lint gate
- `checks.onchain`
  - Aiken build, tests, and formatting gate
- `checks.ci`
  - combined repository gate
- `apps.offchain`, `apps.onchain`, `apps.ci`, `apps.budget-cases`
  - runnable entrypoints over the same check/tool definitions

This means CI is no longer “enter a shell and hope”. It has an explicit Nix build surface:

- `nix build .#checks.x86_64-linux.*` warms the runner store with the verification derivations
- `nix run .#ci` executes the repository gate with stdout visible
- `nix run .#budget-cases` runs the budget measurement executable

## Development

```bash
nix develop
```
