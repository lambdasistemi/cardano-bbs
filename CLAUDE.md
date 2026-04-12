# cardano-bbs-001 Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-11

## Active Technologies

- Haskell (GHC 9.6+) for off-chain, Aiken (latest) for on-chain, Rust (via FFI) for BBS+ core + `zkryptium` v0.6.1 (Rust, BBS+ draft-10), Aiken stdlib BLS12-381 modules, future Cardano integration via `cardano-node-clients` only (001-bbs-credentials)

## Project Structure

```text
src/
tests/
```

## Commands

cargo test [ONLY COMMANDS FOR ACTIVE TECHNOLOGIES][ONLY COMMANDS FOR ACTIVE TECHNOLOGIES] cargo clippy

## Code Style

Haskell (GHC 9.6+) for off-chain, Aiken (latest) for on-chain, Rust (via FFI) for BBS+ core: Follow standard conventions

## Recent Changes

- 001-bbs-credentials: Added Haskell (GHC 9.6+) for off-chain, Aiken (latest) for on-chain, Rust (via FFI) for BBS+ core + `zkryptium` v0.6.1 (Rust, BBS+ draft-10), Aiken stdlib BLS12-381 modules, future Cardano integration via `cardano-node-clients` only

<!-- MANUAL ADDITIONS START -->
- Constitutional rule: `cardano-api` is forbidden in this repository.
- Constitutional rule: all future Cardano integration must use `cardano-node-clients`.
- Constitutional rule: transaction-building is allowed only through `cardano-node-clients`.
<!-- MANUAL ADDITIONS END -->
