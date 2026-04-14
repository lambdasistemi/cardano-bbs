# Feature Specification: Gate Permit Example

**Feature Branch**: `002-permit-example`  
**Created**: 2026-04-13  
**Status**: Draft  
**Input**: User description: "Create a simple example application in cardano-bbs where a regulator issues a credential and an operator selectively discloses only the required claims to prove to a gate that a current permit exists."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Issue an Operator Credential Off-Chain (Priority: P1)

A regulator certifies an operator through an off-chain approval process and issues a credential to that operator. The credential is delivered confidentially to the operator and contains both a credential-specific identifier and the policy claims needed later at the gate.

**Why this priority**: The example has no value unless it starts from a concrete regulator-issued credential for a real actor. This establishes the issuer, the operator, and the permit instance that later has to be proven current.

**Independent Test**: Can be fully tested by defining one operator, one regulator, one credential identifier, and one confidential delivery step, then confirming that the example materials show which facts belong in the credential and which remain off-chain.

**Acceptance Scenarios**:

1. **Given** a regulator and an operator that completed off-chain enrollment, **When** the regulator issues a credential, **Then** the credential contains a unique `credential_id` and the claims later needed for gate admission.
2. **Given** an issued operator credential, **When** a reviewer inspects the example materials, **Then** they can understand that operator registration and credential delivery happen off-chain and are intentionally outside the gate-verification path.

---

### User Story 2 - Present a Current Permit to a Gate (Priority: P1)

An operator arrives at a wasteland gate and is challenged with a fresh nonce. The operator presents a QR that proves three things at once: the operator controls the expected key, the regulator still recognizes a live permit instance for that operator, and the disclosed claims from the credential satisfy the gate policy. The QR reveals only the required claims plus the `credential_id`.

**Why this priority**: This is the central teaching value of the example. It shows that the system is not minting a public permit token, but using a fresh, gate-scoped presentation to prove current authorization with minimal disclosure.

**Independent Test**: Can be fully tested by defining one accepted gate presentation and one rejected gate presentation, both tied to the same operator and regulator state, and confirming that only the accepted one satisfies identity, liveness, and policy requirements.

**Acceptance Scenarios**:

1. **Given** an operator with a valid credential and a fresh nonce from the gate, **When** the operator presents a QR signed by the operator key and discloses the required claims plus `credential_id`, **Then** the gate accepts the presentation only if the regulator state proves that `operator_pkh -> credential_id` is still live.
2. **Given** the same operator and credential, **When** the regulator no longer recognizes that `credential_id` as live for that operator, **Then** the gate rejects the presentation even if the BBS proof itself still verifies under the regulator public key.
3. **Given** a valid presentation for one gate challenge, **When** the same QR is replayed against a different challenge or after the freshness window closes, **Then** the gate rejects it.

---

### User Story 3 - Explain the Privacy and Trust Boundary (Priority: P2)

A developer, auditor, or product stakeholder studies the example to understand exactly what the gate learns, what remains hidden from chain observers, and what trust anchors the gate actually needs.

**Why this priority**: The example should teach the privacy and verification model, not just demonstrate a happy-path QR. Without this, it is easy to confuse issuer-level validity with certificate-instance validity.

**Independent Test**: Can be tested by reviewing the example materials and verifying that they explicitly distinguish off-chain issuance, regulator-held live permit state, the operator signature, the disclosed `credential_id`, and the claims that remain hidden.

**Acceptance Scenarios**:

1. **Given** the completed example, **When** a reviewer follows the flow end to end, **Then** they can identify which data is off-chain, which data is anchored in regulator state, which fields are disclosed to the gate, and which claims remain hidden.
2. **Given** the same example, **When** the reviewer compares accepted and rejected presentations, **Then** they can see that rejection can be caused by stale regulator state, wrong operator identity, replayed nonce, or policy-mismatching disclosed claims.

### Edge Cases

- What happens when the operator presents a valid BBS proof but the `credential_id` no longer appears in the regulator’s live permit state?
- What happens when the operator signs the QR correctly but the signed operator identity does not match the regulator’s current mapping?
- What happens when the operator discloses more claims than the gate requires?
- What happens when the credential was issued by the wrong regulator even though the QR is otherwise well formed?
- What happens when the same QR is replayed under a different gate nonce or against a permit-state proof that is older than the gate accepts?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define a single concrete gate-admission example in which an operator proves current authorization to enter a wasteland.
- **FR-002**: The example MUST identify the regulator, the operator, and the gate as separate actors with distinct responsibilities.
- **FR-003**: The example MUST treat operator registration, regulator approval, and confidential credential delivery as off-chain steps.
- **FR-004**: The regulator-issued credential MUST include a unique `credential_id`.
- **FR-005**: The example MUST define a regulator-maintained live permit state in which `operator_pkh` maps to `credential_id`.
- **FR-006**: The example MUST require the operator presentation to disclose at least `credential_id`.
- **FR-007**: The gate MUST accept a presentation only when the disclosed `credential_id` matches the regulator’s current live permit state for the signed operator identity.
- **FR-008**: The gate MUST require proof that the regulator permit-state root is anchored in the same trusted UTxO set observed by the gate.
- **FR-009**: The gate MUST require the operator to sign the presented QR or equivalent challenge response.
- **FR-010**: The gate MUST require freshness through a gate-issued nonce or equivalent per-scan challenge.
- **FR-011**: The example MUST accept presentations only when the disclosed policy claims satisfy the gate policy.
- **FR-012**: The example MUST reject presentations when identity binding, current permit state, nonce freshness, or policy claims do not match.
- **FR-013**: The example MUST preserve non-required claims as hidden during gate admission.
- **FR-014**: The example MUST avoid requiring a Cardano transaction for every gate scan.
- **FR-015**: The example MUST make clear that issuer public-key validity alone is insufficient and that certificate-instance liveness is required.
- **FR-016**: The example MUST be understandable as a standalone walkthrough without requiring prior knowledge of the broader research discussion.

### Key Entities *(include if feature involves data)*

- **Gate**: The permit consumer at the wasteland entrance. It observes a trusted UTxO-set root, knows the regulator state anchor, issues fresh challenges, and decides whether to admit the operator.
- **Operator**: The certified real-world actor seeking admission. The operator controls the signing key used for gate presentations and holds the confidential credential off-chain.
- **Regulator**: The authority that approves operators off-chain, issues credentials, and maintains the live permit state that maps `operator_pkh` to `credential_id`.
- **Permit Credential**: The regulator-issued credential containing `credential_id`, policy-relevant claims, and additional hidden claims.
- **Live Permit State**: The regulator-maintained authenticated mapping from `operator_pkh` to `credential_id`, whose liveness determines whether a certificate instance remains valid.
- **Gate Presentation**: The nonce-bound QR or equivalent message signed by the operator and backed by both a BBS proof and a proof against current regulator state.
- **Disclosure Set**: The subset of credential claims revealed to the gate. It always includes `credential_id` and may include additional policy claims required for admission.
- **Permit Decision**: The observable outcome of the gate flow, indicating whether the operator is admitted or denied.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A newcomer can identify the regulator, operator, gate, `credential_id`, required claims, hidden claims, and permit outcome from the example materials in under 10 minutes.
- **SC-002**: The example includes at least one accepted gate presentation and one rejected gate presentation for the same operator and credential instance.
- **SC-003**: Reviewers can explain why a valid BBS proof under the regulator public key is still insufficient without a matching live `operator_pkh -> credential_id` proof.
- **SC-004**: In the accepted example flow, at least one credential claim remains hidden while the gate still admits the operator.
- **SC-005**: Reviewers can explain why the example does not require a Cardano transaction per scan and how nonce freshness prevents replay.

## Assumptions

- The example is intended as a teaching and demonstration slice, not as a complete production gate system.
- A single gate-admission scenario is enough for the first version; multiple gate classes and multiple permit classes are out of scope.
- The gate receives trusted UTxO-set roots from an external source and does not itself maintain consensus.
- The operator registration and regulator approval workflow remain off-chain and are intentionally treated as opaque in this example.
- The example may reuse the repository's existing credential issuance and proof-verification capabilities rather than modeling every operational detail of the regulator back office.
