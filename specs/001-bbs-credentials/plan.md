# Implementation Plan: BBS+ Credentials and Unlinkable Authorization

**Branch**: `001-bbs-credentials` | **Date**: 2026-04-11 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-bbs-credentials/spec.md`

## Summary

Implement BBS+ anonymous credentials for Cardano: a Haskell off-chain library for credential issuance and proof derivation (via FFI to `zkryptium` Rust crate), and an Aiken on-chain validator for proof verification using CIP-0381 BLS12-381 built-ins. Additionally, BLS signature aggregation for multi-oracle use cases, which reuses the same on-chain pairing infrastructure.

## Technical Context

**Language/Version**: Haskell (GHC 9.6+) for off-chain, Aiken (latest) for on-chain, Rust (via FFI) for BBS+ core
**Primary Dependencies**: `zkryptium` v0.6.1 (Rust, BBS+ draft-10), Aiken stdlib BLS12-381 modules, `cardano-node-clients` for Cardano integration
**Storage**: N/A — library, no persistent storage
**Testing**: HSpec + QuickCheck (Haskell), Aiken test framework, conformance against IETF test vectors
**Target Platform**: Linux x86_64 (off-chain), Cardano mainnet/testnet (on-chain)
**Project Type**: Library (off-chain) + Smart contract (on-chain)
**Performance Goals**: Proof derivation <1s, on-chain verification within Plutus V3 budget (~2-3B CPU ExUnits for 5 attributes)
**Constraints**: 10B CPU tx budget, ~14KB tx size limit, BLS12-381 curve only
**Scale/Scope**: Credentials with 1-10 attributes

### Cardano Integration Policy

- `cardano-api` is forbidden for this feature.
- When Cardano client integration is needed, it must use `cardano-node-clients`.
- Transaction-building work is permitted through `cardano-node-clients`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Two-Component Architecture | PASS | offchain/ (Haskell) + onchain/ (Aiken) as designed |
| II. Cryptographic Correctness | PASS | Following draft-irtf-cfrg-bbs-signatures-10, IETF test vectors |
| III. Minimal Trusted Surface | PASS | FFI to audited Rust crate (zkryptium), on-chain uses only CIP-0381 built-ins |
| IV. Test Separation | PASS | Unit, integration (round-trip), property (unlinkability), conformance |
| V. Script Budget Awareness | PASS | 2 pairings = ~1.2B CPU, well within 10B budget; benchmarks planned |

## Project Structure

### Documentation (this feature)

```text
specs/001-bbs-credentials/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── offchain-api.md
│   └── onchain-api.md
└── tasks.md
```

### Source Code (repository root)

```text
offchain/
├── cabal.project                     -- pinned Cardano dependency graph for tx builder work
├── cardano-bbs.cabal
├── src/
│   ├── Cardano/BBS/KeyGen.hs         -- key pair generation
│   ├── Cardano/BBS/Credential.hs     -- issuance
│   ├── Cardano/BBS/Proof.hs          -- proof derivation
│   ├── Cardano/BBS/Verify.hs         -- off-chain verification
│   ├── Cardano/BBS/Serialize.hs      -- CBOR encoding for Plutus
│   ├── Cardano/BBS/TxBuild.hs        -- Plutus data bridge for cardano-node-clients
│   ├── Cardano/BBS/FFI.hs            -- Rust FFI bindings to zkryptium
│   └── Cardano/BLS/
│       ├── Sign.hs                   -- BLS signing
│       └── Aggregate.hs             -- BLS aggregation
├── test/
│   ├── Unit/
│   ├── Property/
│   ├── Conformance/                  -- IETF test vector runner
│   └── Integration/                  -- round-trip with Aiken and Cardano tx builder
├── cbits/                            -- Rust FFI glue
│   └── zkryptium-ffi/
│       ├── Cargo.toml
│       └── src/lib.rs
└── fourmolu.yaml

onchain/
├── aiken.toml
├── lib/
│   ├── bbs/
│   │   ├── verify.ak                 -- BBS+ proof verification
│   │   ├── generators.ak            -- generator point computation
│   │   └── types.ak                 -- data types (Proof, Registry)
│   └── bls/
│       ├── aggregate.ak             -- BLS aggregate signature verification
│       └── types.ak
├── validators/
│   ├── bbs_credential.ak            -- BBS+ credential validator
│   └── bls_oracle.ak                -- BLS multi-oracle validator
└── test/

flake.nix                            -- builds both components
justfile                             -- dev recipes
```

**Structure Decision**: Two independent directories mirroring the constitution's two-component architecture. The offchain Haskell library wraps a Rust FFI layer for BBS+ core operations. The onchain Aiken component is self-contained — no Haskell dependency at runtime.

## Complexity Tracking

No constitution violations. No complexity justification needed.
