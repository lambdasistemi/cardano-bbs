# Roadmap

## What Is Done

- project scaffold on `main`
- reproducible Nix baseline
- real CI gate instead of a stub
- Rust `zkryptium` bridge for keygen, sign, verify, proof generation, and proof verification
- Haskell wrappers over the FFI
- fixture-backed conformance tests
- MkDocs site and deployment workflow

## What Is Not Done

The major unfinished items are still substantial:

- Aiken implementation of BBS+ verification
- Aiken tests and budget analysis
- off-chain to on-chain serialization contract hardening
- BLS aggregation support
- revocation
- richer Haskell error modelling

## Recommended Execution Order

1. finish the on-chain verifier
2. add round-trip tests from Haskell outputs into Aiken inputs
3. lock the serialization format
4. add BLS aggregation
5. add revocation

## Why The Docs Are Conservative

This site documents the real state of the repository. It intentionally distinguishes between:

- what the repository is designed to become
- what the code actually does today
