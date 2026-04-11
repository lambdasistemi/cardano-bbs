# Feature Specification: BBS+ Credentials and Unlinkable Authorization

**Feature Branch**: `001-bbs-credentials`
**Created**: 2026-04-11
**Status**: Draft
**Input**: User description: "BBS+ credential issuance, proof derivation, and on-chain verification for unlinkable authorization"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Credential Issuance (Priority: P1)

A regulator (or identity provider) attests that a user is real and authorized. The regulator issues a BBS+ credential containing a set of attributes (e.g., "authorized requester", "jurisdiction: EU", "role: data controller"). The user receives and stores the credential locally.

**Why this priority**: Without credential issuance, nothing else works. This is the foundation — a trusted authority producing a cryptographic attestation over a set of claims about a user.

**Independent Test**: Can be fully tested by issuing a credential with known attributes and verifying the signature is valid. Delivers: a signed credential that the holder can later use to derive proofs.

**Acceptance Scenarios**:

1. **Given** a regulator with a BBS+ key pair, **When** the regulator issues a credential over 3 attributes to a user, **Then** the credential signature verifies against the regulator's public key and the stated attributes.
2. **Given** a credential issued by regulator A, **When** verified against regulator B's public key, **Then** verification fails.
3. **Given** a credential over attributes [a, b, c], **When** any attribute is modified after issuance, **Then** verification fails.

---

### User Story 2 - Unlinkable Proof Derivation (Priority: P1)

A user holding a valid credential derives a zero-knowledge proof for presentation to an operator. The proof attests "I hold a valid credential from this regulator" without revealing which credential or which user. Two proofs derived from the same credential are computationally indistinguishable.

**Why this priority**: Unlinkability is the core value proposition — without it, standard signatures suffice. This is what makes BBS+ structurally different from Ed25519 or ECDSA.

**Independent Test**: Can be tested by deriving two proofs from the same credential and verifying that no algorithm can determine they came from the same holder, while both proofs verify successfully against the regulator's public key.

**Acceptance Scenarios**:

1. **Given** a valid credential, **When** the user derives a proof, **Then** the proof verifies against the regulator's public key without revealing the user's identity or credential.
2. **Given** the same credential, **When** the user derives two proofs at different times, **Then** the two proofs are unlinkable — no information connects them to the same holder.
3. **Given** a valid credential with attributes [a, b, c], **When** the user derives a proof disclosing only attribute [a], **Then** the verifier learns [a] but nothing about [b] or [c].

---

### User Story 3 - On-Chain Proof Verification (Priority: P1)

An operator submits a transaction containing a BBS+ proof as a redeemer. The on-chain validator checks the proof against a registered regulator's public key. If valid, the transaction succeeds — proving that an authorized, attested user submitted the data, without revealing which user.

**Why this priority**: On-chain verification is what makes this usable on Cardano. Without it, the proofs are only checkable off-chain, which requires trusting the operator.

**Independent Test**: Can be tested by constructing a transaction with a BBS+ proof redeemer, submitting it to a validator, and confirming acceptance. Then submitting a forged proof and confirming rejection.

**Acceptance Scenarios**:

1. **Given** a valid BBS+ proof and a registered regulator public key, **When** the proof is submitted as a redeemer, **Then** the on-chain validator accepts the transaction.
2. **Given** an invalid or forged proof, **When** submitted as a redeemer, **Then** the on-chain validator rejects the transaction.
3. **Given** a valid proof but against a different regulator's public key than the one registered, **Then** the on-chain validator rejects the transaction.
4. **Given** a valid proof, **When** the on-chain verification completes, **Then** it fits within Plutus V3 execution budgets (CPU and memory).

---

### User Story 4 - Selective Disclosure (Priority: P2)

A user holding a credential with multiple attributes chooses which attributes to reveal and which to hide when deriving a proof. The verifier (on-chain or off-chain) learns only the disclosed attributes and that the remaining hidden attributes exist and are validly signed — but not their values.

**Why this priority**: Selective disclosure is what separates BBS+ from simpler ZK schemes. It enables nuanced authorization — e.g., prove "I am authorized AND my jurisdiction is EU" without revealing role, name, or credential ID.

**Independent Test**: Can be tested by issuing a credential with 5 attributes, deriving a proof that reveals 2 and hides 3, and verifying that the verifier accepts the proof and learns exactly the 2 disclosed attributes.

**Acceptance Scenarios**:

1. **Given** a credential with attributes [name, role, jurisdiction, issue_date, credential_id], **When** the user derives a proof disclosing only [jurisdiction], **Then** the verifier learns "jurisdiction: EU" and that 4 other attributes are validly signed, but not their values.
2. **Given** the same credential, **When** two proofs are derived disclosing different attribute subsets, **Then** neither proof reveals information about the undisclosed attributes, and the two proofs are unlinkable.

---

### User Story 5 - Credential Revocation (Priority: P3)

The regulator revokes a previously issued credential. After revocation, proofs derived from that credential are rejected by verifiers. The revocation mechanism must not break unlinkability — the revocation list must not reveal which user was revoked to anyone other than the regulator.

**Why this priority**: Revocation is essential for production use but can be deferred for an initial implementation. The core issuance-proof-verification loop works without it.

**Independent Test**: Can be tested by issuing a credential, verifying a proof succeeds, revoking the credential, and verifying a new proof from the same credential is rejected.

**Acceptance Scenarios**:

1. **Given** a revoked credential, **When** the user derives a proof, **Then** the verifier rejects it.
2. **Given** a revocation list with N entries, **When** any non-revoked user derives a proof, **Then** the proof succeeds and the verifier cannot determine the user's position relative to the revocation list.

---

### Edge Cases

- What happens when a credential contains zero attributes? — Proof should still verify (empty disclosure set).
- What happens when all attributes are disclosed? — Degenerates to a standard signature verification; unlinkability is lost (by design, since everything is revealed).
- What happens when the on-chain proof verification exceeds script budgets? — The transaction fails. The system must report budget usage clearly so credential size (number of attributes) can be tuned.
- What happens when a proof is replayed in a different transaction? — The validator must include transaction-specific context (e.g., a nonce or datum hash) in the verification to prevent replay.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow a regulator to generate a BBS+ key pair (signing key + verification key).
- **FR-002**: The system MUST allow a regulator to issue a credential over an ordered list of attributes to a user.
- **FR-003**: The system MUST allow a credential holder to derive a zero-knowledge proof from their credential, choosing which attributes to disclose and which to hide.
- **FR-004**: Two proofs derived from the same credential MUST be computationally indistinguishable (unlinkable) to any verifier.
- **FR-005**: The system MUST provide an off-chain verifier that accepts valid proofs and rejects invalid ones.
- **FR-006**: The system MUST provide an on-chain validator that verifies BBS+ proofs submitted as redeemers, using only BLS12-381 built-in operations available in Plutus V3.
- **FR-007**: On-chain proof verification MUST complete within Plutus V3 execution budgets for credentials with up to 10 attributes.
- **FR-008**: The off-chain proof format and the on-chain verifier MUST use the same serialization — a proof generated off-chain MUST be directly consumable on-chain without transformation.
- **FR-009**: The system MUST support selective disclosure — revealing any subset of credential attributes while hiding the rest.
- **FR-010**: The system MUST prevent proof replay — each proof MUST be bound to a specific transaction context.
- **FR-011**: The system MUST conform to the BBS+ signature scheme as specified in draft-irtf-cfrg-bbs-signatures, using the BLS12-381 curve.

### Key Entities

- **Regulator Key Pair**: A BLS12-381 key pair used to sign credentials. The verification key is published on-chain (e.g., in a reference datum). The signing key is held privately by the regulator.
- **Credential**: A BBS+ signature over an ordered list of attributes, bound to a specific regulator key. Held by the user, never published.
- **Proof**: A zero-knowledge derivation from a credential. Contains disclosed attributes, a proof-of-knowledge for hidden attributes, and a nonce binding it to a specific context. Submitted as a redeemer.
- **Attribute**: A single claim within a credential (e.g., "jurisdiction: EU"). Represented as a scalar field element.
- **Revocation Accumulator**: A cryptographic accumulator tracking revoked credentials. Published on-chain. Proofs of non-membership are included in the ZK proof.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A credential with 5 attributes can be issued and a proof derived in under 1 second on commodity hardware.
- **SC-002**: On-chain verification of a proof (5 attributes, 2 disclosed) completes within Plutus V3 budget limits.
- **SC-003**: Two proofs from the same credential pass a statistical indistinguishability test — no algorithm distinguishes them from proofs of two different credentials with better than 50% probability.
- **SC-004**: All operations pass conformance tests against BBS+ specification test vectors (draft-irtf-cfrg-bbs-signatures).
- **SC-005**: A round-trip test (off-chain issuance → off-chain proof derivation → on-chain verification) succeeds end-to-end on a Cardano testnet.
- **SC-006**: The system handles credentials with 1 to 10 attributes without exceeding on-chain budget limits.

## Assumptions

- Plutus V3 BLS12-381 built-ins (CIP-0381, CIP-0133) are available and functional on Cardano testnet.
- The regulator's verification key is published on-chain as a reference datum or in a well-known location — the mechanism for publishing keys is out of scope for this feature.
- Credential storage on the user side is out of scope — the library produces and consumes credentials as data structures; persistence is the caller's responsibility.
- Revocation (User Story 5) is a separate implementation phase — the core issuance/proof/verification loop does not depend on it.
- The BBS+ specification (draft-irtf-cfrg-bbs-signatures) is stable enough to implement against — if the spec changes, the implementation will need to be updated.
