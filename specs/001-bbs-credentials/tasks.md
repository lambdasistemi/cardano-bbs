# Tasks: BBS+ Credentials and Unlinkable Authorization

**Input**: Design documents from `/specs/001-bbs-credentials/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Project initialization, nix flake, CI, both component scaffolds

- [ ] T001 Create flake.nix with dev shell for Haskell (GHC 9.6+) + Aiken + Rust in flake.nix
- [ ] T002 Create justfile with build, test, format-check, hlint recipes in justfile
- [ ] T003 [P] Create offchain/cardano-bbs.cabal with library structure and dependencies in offchain/cardano-bbs.cabal
- [ ] T004 [P] Create onchain/aiken.toml with project config and stdlib BLS12-381 dependency in onchain/aiken.toml
- [ ] T005 [P] Create offchain/cbits/zkryptium-ffi/Cargo.toml with zkryptium v0.6.1 dependency in offchain/cbits/zkryptium-ffi/Cargo.toml
- [ ] T006 Create .github/workflows/ci.yml with build gate, Haskell build+test, Aiken build+test, formatting jobs in .github/workflows/ci.yml
- [ ] T007 [P] Create offchain/fourmolu.yaml with formatting config in offchain/fourmolu.yaml

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Rust FFI bridge and shared types that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Implement Rust FFI C-API wrapper for zkryptium key generation in offchain/cbits/zkryptium-ffi/src/lib.rs
- [ ] T009 Implement Rust FFI C-API wrapper for zkryptium sign, proof_gen, proof_verify in offchain/cbits/zkryptium-ffi/src/lib.rs
- [ ] T010 Create Haskell FFI bindings module importing C functions in offchain/src/Cardano/BBS/FFI.hs
- [ ] T011 [P] Create Aiken BBS+ types (Proof, RegulatorRegistry) in onchain/lib/bbs/types.ak
- [ ] T012 [P] Create Aiken BLS types (AggregateSignatureRedeemer, OracleRegistry) in onchain/lib/bls/types.ak
- [ ] T013 [P] Create Haskell CBOR serialization module for G1/G2/Scalar matching Aiken format in offchain/src/Cardano/BBS/Serialize.hs
- [ ] T014 Download IETF BBS+ test vectors (bls12-381-sha-256) from decentralized-identity/bbs-signature into offchain/test/Conformance/fixtures/

**Checkpoint**: FFI bridge compiles, Aiken types defined, serialization module ready

---

## Phase 3: User Story 1 — Credential Issuance (Priority: P1) 🎯 MVP

**Goal**: Regulator generates key pair and issues BBS+ credentials over attribute sets

**Independent Test**: Issue a credential with 3 attributes, verify signature against regulator's public key

### Implementation for User Story 1

- [ ] T015 [US1] Implement key pair generation wrapping FFI in offchain/src/Cardano/BBS/KeyGen.hs
- [ ] T016 [US1] Implement credential issuance (sign attributes) wrapping FFI in offchain/src/Cardano/BBS/Credential.hs
- [ ] T017 [US1] Implement credential verification (check signature) wrapping FFI in offchain/src/Cardano/BBS/Verify.hs
- [ ] T018 [US1] Write conformance tests against IETF signature test vectors in offchain/test/Conformance/SignatureSpec.hs
- [ ] T019 [US1] Write unit tests: issue credential, verify succeeds; tamper attribute, verify fails in offchain/test/Unit/CredentialSpec.hs

**Checkpoint**: Can generate keys, issue credentials, verify signatures. IETF test vectors pass.

---

## Phase 4: User Story 2 — Unlinkable Proof Derivation (Priority: P1)

**Goal**: Credential holder derives ZK proofs that are unlinkable across presentations

**Independent Test**: Derive two proofs from same credential, verify both succeed, confirm they share no linkable information

### Implementation for User Story 2

- [ ] T020 [US2] Implement proof derivation (full disclosure) wrapping FFI in offchain/src/Cardano/BBS/Proof.hs
- [ ] T021 [US2] Implement off-chain proof verification wrapping FFI in offchain/src/Cardano/BBS/Verify.hs (extend existing)
- [ ] T022 [US2] Write conformance tests against IETF proof test vectors in offchain/test/Conformance/ProofSpec.hs
- [ ] T023 [US2] Write property test: two proofs from same credential are statistically indistinguishable in offchain/test/Property/UnlinkabilitySpec.hs

**Checkpoint**: Can derive and verify proofs. Unlinkability property holds. IETF proof test vectors pass.

---

## Phase 5: User Story 3 — On-Chain Proof Verification (Priority: P1)

**Goal**: Aiken validator checks BBS+ proof submitted as redeemer using BLS12-381 pairings

**Independent Test**: Construct tx with valid proof redeemer → validator accepts. Forged proof → validator rejects.

### Implementation for User Story 3

- [x] T024 [US3] Implement generator point computation in onchain/lib/bbs/generators.ak
- [x] T025 [US3] Implement BBS+ proof verification (pairing check, challenge recomputation) in onchain/lib/bbs/verify.ak
- [x] T026 [US3] Implement BBS+ credential validator (reads regulator_pk from reference input) in onchain/validators/bbs_credential.ak
- [ ] T027 [US3] Write Aiken unit tests: valid proof accepted, invalid proof rejected in onchain/test/bbs_verify_test.ak
- [x] T028 [US3] Measure and document CPU/memory ExUnit costs for 1, 5, 10 attributes in specs/001-bbs-credentials/budget-report.md
- [ ] T029 [US3] Write round-trip integration test: off-chain issue+prove → serialize → on-chain verify in offchain/test/Integration/RoundTripSpec.hs

**Checkpoint**: End-to-end flow works. Budget fits. Round-trip test passes.

---

## Phase 6: User Story 4 — Selective Disclosure (Priority: P2)

**Goal**: Prove subset of attributes while hiding others

**Independent Test**: Issue 5-attribute credential, derive proof disclosing 2, verify that verifier learns exactly 2 values

### Implementation for User Story 4

- [ ] T030 [US4] Extend proof derivation to accept disclosure set (indices to reveal) in offchain/src/Cardano/BBS/Proof.hs
- [ ] T031 [US4] Extend on-chain verifier to handle partial disclosure (reconstruct B from disclosed subset) in onchain/lib/bbs/verify.ak
- [ ] T032 [US4] Write conformance tests for selective disclosure against IETF proof fixtures in offchain/test/Conformance/SelectiveDisclosureSpec.hs
- [ ] T033 [US4] Write Aiken test: partial disclosure proof accepted, disclosed values match in onchain/test/bbs_selective_test.ak

**Checkpoint**: Selective disclosure works both off-chain and on-chain. IETF fixtures pass.

---

## Phase 7: User Story 6 — BLS Signature Aggregation (Priority: P2)

**Goal**: Multiple oracles sign same message, aggregate into one signature, verify on-chain in single pairing check

**Independent Test**: 3 oracles sign, aggregate, verify aggregate on-chain. Cost is constant regardless of signer count.

### Implementation for User Story 6

- [ ] T034 [P] [US6] Implement BLS key generation and signing in offchain/src/Cardano/BLS/Sign.hs
- [ ] T035 [P] [US6] Implement BLS signature aggregation (G1 point addition) in offchain/src/Cardano/BLS/Aggregate.hs
- [ ] T036 [US6] Implement BLS aggregate signature verification in onchain/lib/bls/aggregate.ak
- [ ] T037 [US6] Implement BLS oracle validator (reads oracle_pks + quorum from datum) in onchain/validators/bls_oracle.ak
- [ ] T038 [US6] Write Aiken tests: valid aggregate accepted, insufficient quorum rejected, forged sig rejected in onchain/test/bls_aggregate_test.ak
- [ ] T039 [US6] Write CBOR serialization for BLS signatures and aggregate in offchain/src/Cardano/BBS/Serialize.hs (extend)
- [ ] T040 [US6] Write round-trip integration test: off-chain sign+aggregate → on-chain verify in offchain/test/Integration/BLSRoundTripSpec.hs

**Checkpoint**: Multi-oracle aggregation works end-to-end. Constant verification cost confirmed.

---

## Phase 8: User Story 5 — Credential Revocation (Priority: P3)

**Goal**: Revoke credentials without breaking unlinkability

**Independent Test**: Issue credential, verify proof succeeds, revoke, verify new proof fails

### Implementation for User Story 5

- [ ] T041 [US5] Research and select revocation scheme (accumulator-based, compatible with BBS+) — document in specs/001-bbs-credentials/research.md (append)
- [ ] T042 [US5] Implement revocation accumulator off-chain (issue non-membership witness with credential) in offchain/src/Cardano/BBS/Revocation.hs
- [ ] T043 [US5] Extend proof derivation to include non-membership proof in offchain/src/Cardano/BBS/Proof.hs
- [ ] T044 [US5] Extend on-chain verifier to check revocation accumulator from reference input in onchain/lib/bbs/verify.ak
- [ ] T045 [US5] Write tests: revoked credential proof rejected, non-revoked proof accepted, unlinkability preserved in offchain/test/Unit/RevocationSpec.hs

**Checkpoint**: Revocation works without breaking unlinkability. Accumulator fits in script budget.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T046 [P] Add Haddock documentation to all public modules in offchain/src/
- [ ] T047 [P] Add Aiken module documentation in onchain/lib/
- [ ] T048 Run quickstart.md validation — ensure all code snippets work
- [ ] T049 Create comprehensive budget report: all verification scenarios with ExUnit costs in specs/001-bbs-credentials/budget-report.md
- [ ] T050 Security review: verify no secret key material leaks through serialization or proof structures

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **US1 Credential Issuance (Phase 3)**: Depends on Foundational
- **US2 Unlinkable Proof (Phase 4)**: Depends on US1 (needs credentials to derive proofs from)
- **US3 On-Chain Verification (Phase 5)**: Depends on US2 (needs proofs to verify)
- **US4 Selective Disclosure (Phase 6)**: Depends on US3 (extends both proof derivation and on-chain verification)
- **US6 BLS Aggregation (Phase 7)**: Depends on Foundational only — can run in parallel with US1-US4
- **US5 Revocation (Phase 8)**: Depends on US3 (extends verification with accumulator check)
- **Polish (Phase 9)**: Depends on all desired user stories

### User Story Dependencies

```
Foundational
├── US1 (Credential Issuance)
│   └── US2 (Unlinkable Proof)
│       └── US3 (On-Chain Verification)
│           ├── US4 (Selective Disclosure)
│           └── US5 (Revocation)
└── US6 (BLS Aggregation) — independent track
```

### Parallel Opportunities

- T003, T004, T005, T007 (Setup: cabal, aiken.toml, Cargo.toml, fourmolu) — all parallel
- T011, T012, T013 (Foundational: Aiken BBS types, BLS types, Haskell serialization) — all parallel
- T034, T035 (US6: BLS sign, BLS aggregate) — parallel
- US6 (BLS Aggregation) can run entirely in parallel with the US1→US2→US3→US4 chain

---

## Implementation Strategy

### MVP First (US1 + US2 + US3)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (FFI bridge)
3. Complete Phase 3: US1 — credential issuance works
4. Complete Phase 4: US2 — unlinkable proofs work
5. Complete Phase 5: US3 — on-chain verification works
6. **STOP and VALIDATE**: End-to-end round-trip on testnet

### Incremental Delivery

1. MVP (US1+US2+US3) → core credential flow works
2. Add US4 (Selective Disclosure) → nuanced authorization
3. Add US6 (BLS Aggregation) → multi-oracle support (can be done earlier, independent track)
4. Add US5 (Revocation) → production-ready credential lifecycle
5. Polish → documentation, budget report, security review

---

## Notes

- US6 (BLS Aggregation) is an independent track — can be worked on by a separate agent/developer from day one after Foundational phase
- The FFI bridge (T008-T010) is the highest-risk task — if zkryptium's C API is difficult, consider switching to bbs_plus from docknetwork/crypto
- Budget measurement (T028) should happen early in US3 — if BBS+ verification exceeds budget, the on-chain design needs revision before investing in US4/US5
