# Feature Specification: Qualified Action Permit Example

**Feature Branch**: `002-permit-example`  
**Created**: 2026-04-13  
**Status**: Draft  
**Input**: User description: "Create a simple example application in cardano-bbs where a regulator issues a credential and a user selectively discloses only the required claims to obtain an on-chain permit for a qualified action."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Issue Example Permit Credentials (Priority: P1)

A regulator prepares an example credential for a user that represents permission to perform a qualified action. The credential includes multiple claims, but the example remains simple enough to explain the flow to a newcomer.

**Why this priority**: The example has no value unless it starts from a concrete credential that represents a real permission. This is the minimum slice needed to demonstrate the pattern.

**Independent Test**: Can be fully tested by issuing the example credential with the defined claims and confirming that it is recognized as a valid permit credential for the example scenario.

**Acceptance Scenarios**:

1. **Given** a regulator and an example permit policy, **When** the regulator issues a credential to a user, **Then** the credential contains the claims required by that policy and is valid for later presentation.
2. **Given** an issued example permit credential, **When** a reviewer inspects the example materials, **Then** they can understand which claims the credential contains and what qualified action it is meant to authorize.

---

### User Story 2 - Obtain an On-Chain Permit Through Selective Disclosure (Priority: P1)

A user holding the example credential requests permission to perform the qualified action. The user discloses only the claims required by the example policy and keeps the rest hidden. The on-chain permit path accepts or rejects the request based on those disclosed claims.

**Why this priority**: This is the central teaching value of the example. It shows that the system is not just issuing credentials, but using selective disclosure to authorize an action without exposing the full credential.

**Independent Test**: Can be fully tested by presenting the example credential for the qualified action and confirming that the permit is granted when the required claims are disclosed and denied when they are not.

**Acceptance Scenarios**:

1. **Given** a user with a valid example permit credential, **When** the user discloses exactly the required claims for the qualified action, **Then** the on-chain permit request succeeds.
2. **Given** a user with the same credential, **When** the user omits a required claim or discloses a claim set that does not satisfy the policy, **Then** the on-chain permit request is rejected.
3. **Given** a user with a valid example credential containing additional claims, **When** the user requests the qualified action, **Then** undisclosed claims remain hidden throughout the permit flow.

---

### User Story 3 - Explain the Privacy Boundary (Priority: P2)

A developer, auditor, or product stakeholder studies the example to understand exactly what becomes visible during the permit request and what remains private.

**Why this priority**: The example should teach the privacy model, not just demonstrate a happy-path transaction. Without this, it is easy to misunderstand selective disclosure as ordinary identity disclosure.

**Independent Test**: Can be tested by reviewing the example materials and verifying that they explicitly distinguish disclosed claims, hidden claims, and the permit decision outcome.

**Acceptance Scenarios**:

1. **Given** the completed example, **When** a reviewer follows the flow end to end, **Then** they can identify which claims were disclosed, which were hidden, and why the permit decision was made.
2. **Given** the same example, **When** the reviewer compares accepted and rejected requests, **Then** they can see that the difference is driven by policy-relevant claims rather than full credential disclosure.

### Edge Cases

- What happens when a user discloses more claims than the example policy requires?
- What happens when the credential is valid but issued by the wrong regulator for the example permit?
- What happens when the disclosed claims satisfy part of the example policy but not all of it?
- What happens when the same credential is presented twice for different qualified actions with different disclosure requirements?
- What happens when the permit request is structurally valid but reuses a presentation context that should no longer be accepted?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define a single simple example of a qualified action that requires a permit decision.
- **FR-002**: The system MUST define the example permit policy in terms of named credential claims required for that action.
- **FR-003**: The system MUST allow a regulator to issue an example credential containing both policy-relevant claims and additional non-required claims.
- **FR-004**: The system MUST allow a user to request the example permit by presenting the credential with selective disclosure.
- **FR-005**: The example permit flow MUST accept requests only when the disclosed claims satisfy the example policy.
- **FR-006**: The example permit flow MUST reject requests when the disclosed claims do not satisfy the example policy.
- **FR-007**: The example MUST preserve non-required claims as hidden during permit requests.
- **FR-008**: The example MUST make clear which claims are required, which claims are optional, and which claims remain hidden.
- **FR-009**: The example MUST include at least one accepted presentation and at least one rejected presentation for the same qualified action.
- **FR-010**: The example MUST be understandable as a standalone walkthrough without requiring prior knowledge of the full research discussion behind the repository.

### Key Entities *(include if feature involves data)*

- **Qualified Action**: The single example operation that requires authorization. It defines the permit decision being requested.
- **Permit Policy**: The rule set describing which disclosed claims are necessary for the qualified action to be allowed.
- **Permit Credential**: The regulator-issued credential containing claims about the user, including both required and non-required claims.
- **Disclosure Set**: The subset of claims revealed by the user when requesting the permit.
- **Permit Decision**: The observable outcome of the example flow, indicating whether the qualified action is allowed or denied.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A newcomer can identify the qualified action, required claims, hidden claims, and permit outcome from the example materials in under 10 minutes.
- **SC-002**: The example includes at least one accepted permit request and one rejected permit request that differ only in policy-relevant disclosed claims.
- **SC-003**: In the accepted example flow, at least one credential claim remains hidden while the permit is still granted.
- **SC-004**: Reviewers can explain the privacy boundary of the example without needing to inspect repository internals outside the example materials.

## Assumptions

- The example is intended as a teaching and demonstration slice, not as a full end-user product.
- A single qualified action is enough for the first version of the example; multiple permit types are out of scope.
- The regulator, user, and permit policy all belong to the same demonstration scenario and do not need external interoperability in the first version.
- The example may reuse the repository's existing credential issuance and on-chain verification capabilities rather than introducing a separate application domain.
