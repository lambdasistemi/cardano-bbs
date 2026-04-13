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
- `packages.zkryptium-ffi`
  - Rust FFI shared library consumed by the Haskell off-chain package
- `packages.offchain-library`
  - Haskell off-chain library built as a real derivation
- `checks.offchain-tests`
  - Haskell test suite derivation for the off-chain package
- `packages.onchain-blueprint`
  - builds the deployable validator blueprint from [onchain/plutus.json](/code/cardano-bbs-verify/onchain/plutus.json)
- `packages.budget-cases`
  - runnable budget measurement tool from [offchain/app/BudgetCases.hs](/code/cardano-bbs-verify/offchain/app/BudgetCases.hs)
- `checks.offchain-format`
  - Fourmolu formatting check for the off-chain sources
- `checks.offchain-lint`
  - HLint check for the off-chain sources
- `checks.onchain`
  - Aiken build, tests, and formatting gate
- `apps.offchain-tests`, `apps.offchain-format`, `apps.offchain-lint`, `apps.onchain`, `apps.budget-cases`
  - runnable entrypoints for the single CI checks

This means CI is no longer “enter a shell and hope”. It has an explicit Nix build surface:

- `nix build .#checks.x86_64-linux.offchain-library .#checks.x86_64-linux.offchain-tests .#checks.x86_64-linux.onchain .#checks.x86_64-linux.onchainBlueprint` realizes the build-heavy derivations first
- `nix run .#offchain-tests` executes the prebuilt off-chain test component
- `nix run .#offchain-format` and `nix run .#offchain-lint` execute the single source checks
- `nix run .#onchain` executes the on-chain gate with stdout visible
- `nix run .#budget-cases` runs the budget measurement executable

## Development

```bash
nix develop
```
