# Cardano BBS Constitution

## Core Principles

### I. Two-Component Architecture

The project is split into two independent components with a shared specification:

- **offchain/** — Haskell library for BBS+ credential issuance, proof derivation, and serialization. Runs on the client/oracle side.
- **onchain/** — Aiken validators for BBS+ proof-of-knowledge verification using CIP-0381 BLS12-381 built-ins. Runs on-chain in Plutus V3.

Both components implement the same BBS+ specification. The on-chain verifier must accept every proof the off-chain library produces, and reject everything else.

### II. Cryptographic Correctness

BBS+ is a pairing-based signature scheme. Correctness is non-negotiable:

- All operations must be tested against known test vectors (W3C BBS+ test vectors, RFC draft vectors)
- The on-chain verifier must be equivalent to the off-chain verifier — same verification equation, same serialization
- No custom cryptographic constructions — implement the standard BBS+ scheme (draft-irtf-cfrg-bbs-signatures)
- Security properties (unlinkability, unforgeability, selective disclosure) must be preserved

### III. Minimal Trusted Surface

The off-chain library handles key generation, credential issuance, and proof derivation — security-critical operations. The on-chain validator only verifies proofs.

- Off-chain: prefer FFI to audited Rust crates over pure Haskell reimplementation for core pairing arithmetic
- On-chain: use only CIP-0381 built-ins (bls12_381_G1_add, bls12_381_G2_add, bls12_381_millerLoop, bls12_381_finalVerify, etc.) — no custom curve arithmetic
- Serialization format must be deterministic and canonical

### IV. Test Separation

- **Unit tests**: each component tested independently — off-chain proof generation, on-chain proof verification
- **Integration tests**: round-trip tests — off-chain generates credential + proof, on-chain verifier accepts it
- **Property tests**: unlinkability (two proofs from same credential are indistinguishable), unforgeability (random proofs rejected)
- **Conformance tests**: against BBS+ specification test vectors

### V. Script Budget Awareness

On-chain BBS+ verification must fit within Plutus V3 execution budgets. Every on-chain change must be evaluated for CPU and memory cost. If verification exceeds budget, the design must be revised (e.g., proof compression, batching) rather than assuming future budget increases.

### VI. Cardano Integration Boundary

Cardano integration rules are constitutional for this repository:

- `cardano-api` is forbidden in this codebase.
- All future Cardano client integration must go through `cardano-node-clients`.
- No transaction-building implementation may be added until tx-builder support lands in `cardano-node-clients`.

Implications:

- Pure cryptography, serialization, and Aiken validator work may continue without Cardano client dependencies.
- Any task that would otherwise introduce transaction construction must remain blocked, be deferred, or be rewritten around `cardano-node-clients` once the required tx-builder support exists.
- Dependency or architectural proposals that reintroduce `cardano-api` are constitutionally invalid and must be rejected.

## Domain Constraints

### BBS+ Specification

Follow draft-irtf-cfrg-bbs-signatures. The signature scheme operates over BLS12-381:

- Signatures in G1, public keys in G2 (or vice versa per spec variant)
- Proof of knowledge via Schnorr-style protocol
- Selective disclosure: reveal subset of signed messages while hiding others
- Unlinkability: two presentations of the same credential are computationally indistinguishable

### Cardano Integration

- On-chain: Aiken validators using native BLS12-381 built-ins (CIP-0381, CIP-0133)
- Off-chain: Haskell library producing redeemers consumable by the Aiken validator
- Cardano client integration, when introduced, must use `cardano-node-clients` only
- Transaction-building is explicitly deferred until `cardano-node-clients` ships the required tx-builder support
- Serialization: CBOR for on-chain data, matching Aiken's expected format
- The redeemer carries the BBS+ proof; the validator checks the pairing equation

### Regulatory Context

This library enables the unlinkable authorization pattern from the cardano-for-regulators framework. The primary use case is anonymous credentials where:

- An identity provider issues BBS+ credentials to attested users
- Users derive unlinkable ZK proofs for each interaction
- Operators verify authorization without correlating user activity

Design decisions must preserve this use case — unlinkability is the feature, not a side effect.

## Development Workflow

- Nix-first: both components build via nix flake
- PRs required for all changes, linear history
- CI gates: build, test, formatting (fourmolu for Haskell, aiken fmt for Aiken)
- Commits: conventional commits, one feature per commit, every commit must compile
- Lint before push: fourmolu + hlint for Haskell

## Governance

This constitution governs all development decisions. Amendments require explicit discussion and documentation.

**Version**: 1.0.0 | **Ratified**: 2026-04-11
