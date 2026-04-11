# Getting Started

## Development Shell

Start from the flake-managed development shell:

```bash
nix develop
```

The shell provides:

- GHC and Cabal
- Rust and Cargo
- Aiken
- Fourmolu
- HLint

## Common Commands

```bash
just build
just test
just ci
```

`just ci` is the main verification entrypoint used by CI. It currently does all of the following:

1. builds the Rust FFI bridge
2. builds the Haskell library
3. builds the Aiken project
4. runs the Haskell tests
5. runs `aiken check`
6. enforces formatting
7. runs HLint

## Rust FFI Note

The Haskell library links against the Rust cdylib built in:

```text
offchain/cbits/zkryptium-ffi/target/release/
```

The `just` recipes handle the required build order and library path setup for you. Running `cabal build` directly without that shared library available is the wrong workflow.

## Current Verification Baseline

The off-chain test suite validates:

- deterministic reproduction of an imported IETF signature fixture
- verification of an imported IETF signature fixture
- verification of an imported IETF proof fixture
- local round-trip issuance and selective disclosure proof checks
