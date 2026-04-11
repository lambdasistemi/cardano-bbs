# Research: BBS+ Credentials

## BBS+ Specification

**Decision**: Implement draft-irtf-cfrg-bbs-signatures-10 (2026-01-08), ciphersuite BLS12-381-SHA-256.
**Rationale**: Latest stable IETF draft. SHA-256 ciphersuite is more widely implemented and tested. SHAKE-256 variant can be added later.
**Alternatives considered**: Original academic BBS+ paper (used by older crates) — rejected because IETF draft has better test vector coverage and is the convergence target.

## Verification Equation

**Decision**: On-chain verifier implements the CoreProofVerify pairing check: `e(Abar, W) · e(Bbar, -BP2) == Identity_GT`
**Rationale**: This is 2 miller loops + 1 final verify. In Aiken: `final_exponentiation(miller_loop(Abar, W), miller_loop(Bbar, neg_BP2))`. Plus (1+R) G1 scalar multiplications for disclosed message reconstruction.
**Alternatives considered**: Single-pairing optimizations — not applicable to BBS+ proof verification structure.

## On-Chain Budget Feasibility

**Decision**: BBS+ proof verification fits within Plutus V3 budgets for up to ~10 attributes.
**Rationale**: 2 millerLoop (402M each = 804M) + 1 finalVerify (389M) = ~1.2B CPU for the pairing check alone. Plus G1 scalar multiplications for disclosed message reconstruction. Total estimated ~2-3B CPU for 5 attributes. Tx budget is 10B CPU. Comfortable margin.
**Alternatives considered**: If budget becomes tight, split verification across multiple transactions — but not needed based on these numbers.

## BLS Aggregate Signature Verification

**Decision**: Aggregate BLS verification is one pairing check: `e(sig_agg, G2_gen) == e(H(msg), pk_agg)`. Same cost structure as a single BBS+ pairing — ~800M CPU.
**Rationale**: Aggregation is G1 point addition off-chain. On-chain cost is constant regardless of signer count. Shares the same millerLoop/finalVerify infrastructure as BBS+.

## Off-Chain: Rust FFI Strategy

**Decision**: Use `zkryptium` (v0.6.1) via FFI for off-chain BBS+ operations.
**Rationale**: Tracks draft-10 explicitly, supports both ciphersuites, C-friendly crate structure. Apache-2.0 license.
**Alternatives considered**:
- `bbs_plus` from docknetwork/crypto — more features but depends on arkworks stack (heavier FFI surface)
- Pure Haskell implementation — rejected per constitution (Principle III: prefer FFI to audited crates)
- `mattrglobal/ffi-bbs-signatures` — wraps older pre-IETF `bbs` crate, not draft-10 compliant

## On-Chain: Aiken Implementation

**Decision**: Implement BBS+ proof verifier in Aiken using stdlib BLS12-381 modules.
**Rationale**: All required primitives available: `g1.add`, `g1.scale`, `g1.hash_to_group`, `pairing.miller_loop`, `pairing.final_exponentiation`, `scalar` arithmetic. Existing projects (plutus-accumulator, ak-381) demonstrate the pattern.
**Alternatives considered**: Plutus Haskell validator — rejected because Aiken has better BLS12-381 ergonomics and existing community examples.

## Serialization

**Decision**: CBOR encoding for on-chain data. BBS+ proof components (3 G1 points + scalars) serialized as a CBOR array matching Aiken's expected format. Off-chain library produces CBOR directly.
**Rationale**: Aiken deserializes CBOR natively. G1 points are 48 bytes compressed, scalars are 32 bytes big-endian, per the IETF draft encoding.
**Alternatives considered**: Raw concatenation (draft's native format) — would require custom Aiken parsing. CBOR wrapping adds minimal overhead and matches the ecosystem.

## Test Vectors

**Decision**: Use fixtures from `decentralized-identity/bbs-signature` repository (bls12-381-sha-256 directory).
**Rationale**: 15+ proof fixtures with full intermediate traces (Abar, Bbar, D, challenge, scalars). Enables debugging each step independently.
**Alternatives considered**: Draft appendix vectors — fewer cases, less debugging detail.

## Existing Aiken BLS12-381 Projects (Reference)

| Project | What it does | Relevance |
|---|---|---|
| `perturbing/plutus-accumulator` | Bilinear accumulator with membership proofs | Pairing pattern, Aiken + Haskell cross-validation |
| `Modulo-P/ak-381` | Groth16 SNARK verifier | Multi-pairing pattern in Aiken |
| `ilap/bls` | BLS signature verify | Basic sign/verify, simpler than BBS+ |

## Data Structures (from draft-10)

**Signature**: `(A: G1, e: Scalar)` — 80 bytes
**Proof**: `(Abar: G1, Bbar: G1, D: G1, e^: Scalar, r1^: Scalar, r3^: Scalar, [m^_j: Scalar; U], c: Scalar)` — 272 + 32·U bytes (U = undisclosed messages)
**Public key**: G2 point — 96 bytes compressed
