# ZK Selective Disclosure

How BBS+ lets a holder prove facts about their credentials without
revealing the credentials themselves — or letting verifiers link
presentations to the same holder.

!!! note "Mapping to cardano-bbs API"
    The concepts below map directly to the Haskell API in this repo:

    | Concept | cardano-bbs type |
    |---------|-----------------|
    | Issuer secret | `SecretKey` |
    | Issuer public key | `PublicKey` |
    | Credential (signed attributes) | `Credential` |
    | Attribute value | `Attribute` |
    | Which attributes to reveal | `DisclosureSet` ([Int]) |
    | ZK proof | `Proof` |
    | Presentation nonce | `PresentationHeader` |

---

## The idea in one diagram

```mermaid
sequenceDiagram
    participant Issuer
    participant Holder
    participant Verifier

    Issuer->>Holder: Credential = BBS+ signature<br/>over all Attributes

    Note over Holder: Picks which attributes to disclose<br/>(DisclosureSet) + fresh PresentationHeader

    Holder->>Verifier: Disclosed attributes<br/>+ Proof (opaque bytes)<br/>+ DisclosureSet indices

    Note over Verifier: verifyProof(pk, header,<br/>  presentationHeader,<br/>  disclosedAttributes,<br/>  disclosureSet, proof)<br/>→ true ✓<br/><br/>Learns disclosed values only.<br/>Cannot recover hidden attributes.<br/>Cannot link to other presentations.
```

---

## Data structures

### Credential attributes

A credential is an ordered list of `Attribute` values.
The issuer signs all of them together with a single BBS+ signature.

```haskell
-- In cardano-bbs:
issueCredential :: SecretKey -> PublicKey -> Maybe Header -> [Attribute] -> IO Credential
```

For example, a government ID credential might contain:

| Index | Attribute |
|-------|----------|
| 0 | name = "Alice" |
| 1 | age = "25" |
| 2 | address = "Rome" |
| 3 | id = "XK-472" |

The `Credential` is the BBS+ signature over this entire list.

### Disclosure set

A `DisclosureSet` is a list of indices selecting which attributes to reveal:

| DisclosureSet | What verifier sees |
|--------------|-------------------|
| `[1]` | age = "25" (index 1 only) |
| `[0, 2]` | name = "Alice", address = "Rome" |
| `[]` | Nothing (pure existence proof) |
| `[0,1,2,3]` | Everything (no privacy) |

### Proof

The `Proof` is an opaque byte string (~300–400 bytes depending on
hidden attribute count). It contains no cleartext attribute values
and no issuer signature bytes.

```haskell
-- Proof size formula:
proofBytes totalMessages disclosedCount =
  272 + 32 * max 0 (totalMessages - disclosedCount)
```

Each proof incorporates a fresh `PresentationHeader` (holder nonce),
making every proof unique even for the same credential and disclosure set.

---

## Protocol phases

### Phase 1 — Key generation

The issuer generates a BBS+ key pair on the BLS12-381 curve.

```mermaid
sequenceDiagram
    participant Issuer

    Note over Issuer: generateKeyPair :: IO (SecretKey, PublicKey)<br/><br/>SecretKey: scalar on BLS12-381<br/>PublicKey: point on G2<br/><br/>PublicKey is published.<br/>SecretKey is kept private.
```

!!! info "No trusted setup ceremony needed"
    BBS+ uses **pairing-based** cryptography on BLS12-381 but does **not**
    require a multi-party trusted setup ceremony. The issuer generates
    keys directly. This is different from zk-SNARKs (Groth16, PLONK)
    which need a ceremony to produce a Structured Reference String.
    See [Trusted Setup Ceremony](zk-ceremony.md) for the SNARK case.

### Phase 2 — Credential issuance

The issuer signs the holder's attributes.

```mermaid
sequenceDiagram
    participant Issuer
    participant Holder

    Note over Issuer: issueCredential(sk, pk,<br/>  header,<br/>  [ Attribute "Alice"<br/>  , Attribute "25"<br/>  , Attribute "Rome"<br/>  , Attribute "XK-472" ])

    Issuer->>Holder: Credential<br/>(BBS+ signature: opaque bytes)<br/>+ all Attribute values<br/>+ PublicKey

    Note over Holder: Stores privately:<br/>  • Credential (the signature)<br/>  • All Attribute values<br/>  • PublicKey (for proof generation)
```

The `Credential` is a BBS+ signature — a single compact value
(~112 bytes) that commits to **all** attributes simultaneously.

### Phase 3 — Proof generation (selective disclosure)

The holder reveals only chosen attributes and generates a ZK proof
for the rest.

```mermaid
sequenceDiagram
    participant Holder

    Note over Holder: Wants to prove age ≥ 18<br/>by disclosing attribute index 1 (age)<br/><br/>Holder constructs:<br/>  disclosureSet = [1]<br/>  presentationHeader = fresh nonce

    Note over Holder: deriveProof(<br/>  pk,<br/>  credential,<br/>  header,<br/>  presentationHeader,<br/>  [Attribute "Alice",<br/>   Attribute "25",<br/>   Attribute "Rome",<br/>   Attribute "XK-472"],<br/>  [1])

    Note over Holder: Internally BBS+ does:<br/>  1. Re-randomize the credential signature<br/>     (introduces fresh blinding factors)<br/>  2. Commit to hidden attributes<br/>     (indices 0, 2, 3 are hidden)<br/>  3. Compute Fiat-Shamir challenge<br/>     (binds to presentationHeader + disclosed values)<br/>  4. Produce response scalars<br/><br/>→ Proof (~304 bytes for 4 msgs, 1 disclosed)

    Note over Holder: Sends to verifier:<br/>  • disclosureSet: [1]<br/>  • disclosed attribute: Attribute "25"<br/>  • Proof (opaque bytes)<br/>  • presentationHeader
```

#### What the proof contains vs. what it hides

```mermaid
graph TD
    subgraph "Proof internals (opaque to verifier)"
        P1["Ā: re-randomized signature element (G1)"]
        P2["B̄: blinded signature element (G1)"]
        P3["d: commitment element (G1)"]
        P4["ê: challenge response for signature randomness"]
        P5["r̂₁, r̂₃: challenge responses for blinding"]
        P6["m̂[0], m̂[2], m̂[3]: challenge responses<br/>for HIDDEN attribute values"]
        P7["c: Fiat-Shamir challenge scalar"]
    end

    subgraph "Sent alongside proof (cleartext)"
        C1["disclosureSet: [1]"]
        C2["disclosed attribute: '25' (the age)"]
        C3["presentationHeader: fresh nonce"]
    end

    subgraph "NOT in the proof at all"
        N1["Original Credential signature bytes"]
        N2["Hidden attribute values<br/>('Alice', 'Rome', 'XK-472')"]
        N3["SecretKey"]
    end

    style P6 fill:#c44,stroke:#333,color:#fff
    style N1 fill:#6b6,stroke:#333,color:#fff
    style N2 fill:#6b6,stroke:#333,color:#fff
    style N3 fill:#6b6,stroke:#333,color:#fff
```

### Phase 4 — Verification

The verifier checks the proof using only the disclosed attributes
and the issuer's public key.

```mermaid
sequenceDiagram
    participant Holder
    participant Verifier

    Holder->>Verifier: disclosureSet: [1]<br/>disclosed: [Attribute "25"]<br/>presentationHeader: nonce<br/>Proof (~304 bytes)

    Note over Verifier: verifyProof(<br/>  pk,<br/>  header,<br/>  presentationHeader,<br/>  [Attribute "25"],<br/>  [1],<br/>  proof)

    Note over Verifier: Internally BBS+ does:<br/>  1. Recompute Fiat-Shamir challenge<br/>     from disclosed values + proof elements<br/>  2. Check pairing equation:<br/>     e(Ā, pk) · e(B̄, -G₂) = 1<br/>  3. Verify challenge responses<br/>     are consistent with commitments<br/><br/>→ true ✓

    Note over Verifier: Learned:<br/>  • Attribute at index 1 = "25"<br/>  • Credential was signed by pk<br/>  • Credential has ≥ 4 attributes<br/><br/>Does NOT know:<br/>  • Values at indices 0, 2, 3<br/>  • The original Credential (signature)<br/>  • Any correlator to link presentations
```

---

## Unlinkability: the BBS+ mechanism

Unlike generic zk-SNARKs where unlinkability comes from circuit randomness,
BBS+ achieves it through **signature re-randomization**.

```mermaid
graph TD
    subgraph "Original Credential"
        SIG["Credential = (A, e, s)<br/>BBS+ signature on all attributes"]
    end

    subgraph "Presentation 1 (to bar)"
        R1["Fresh blinding: r₁, r₂"]
        RE1["Ā₁ = A · r₁<br/>B̄₁ = ... (re-randomized)"]
        P1["Proof₁ incorporating Ā₁, B̄₁"]
    end

    subgraph "Presentation 2 (to bank)"
        R2["Fresh blinding: r₃, r₄"]
        RE2["Ā₂ = A · r₃<br/>B̄₂ = ... (re-randomized)"]
        P2["Proof₂ incorporating Ā₂, B̄₂"]
    end

    SIG --> R1 --> RE1 --> P1
    SIG --> R2 --> RE2 --> P2

    RESULT["Ā₁ ≠ Ā₂, B̄₁ ≠ B̄₂, Proof₁ ≠ Proof₂<br/>No shared value between presentations<br/>→ UNLINKABLE"]

    P1 --> RESULT
    P2 --> RESULT

    style SIG fill:#c44,stroke:#333,color:#fff
    style RESULT fill:#4a4,stroke:#333,color:#fff
```

The `PresentationHeader` (holder nonce) is mixed into the Fiat-Shamir
challenge, adding an additional source of uniqueness per presentation.

---

## Comparison with the Lean spec

The [Lean 4 specification](https://github.com/lambdasistemi/cardano-bbs/blob/main/lean/ZkSelectiveDisclosure.lean)
models a generic ZK selective disclosure system. Here is how it maps
to the BBS+ specifics in this repo:

| Lean spec | BBS+ (cardano-bbs) |
|-----------|-------------------|
| `SecretKey` | `SecretKey` (BLS12-381 scalar) |
| `PublicKey` | `PublicKey` (G2 point) |
| `Credential` (attribute record) | `[Attribute]` (ordered list) |
| `CredentialWitness.issuerSig` | `Credential` (BBS+ signature) |
| `Circuit` | Implicit — BBS+ has one fixed verification equation |
| `ProvingKey` / `VerificationKey` | Not needed — BBS+ uses `PublicKey` directly |
| `trustedSetup` ceremony | Not needed — key generation is direct |
| `Randomness` → `prove()` | Fresh blinding factors + `PresentationHeader` |
| `Proof pubInputs` | `Proof` (~300 bytes) |
| `ZkPresentation.publicInputs` | Disclosed `[Attribute]` + `DisclosureSet` + `PresentationHeader` |
| `verify(vk, pubInputs, proof)` | `verifyProof(pk, header, ph, attrs, ds, proof)` |

The key simplification in BBS+ compared to generic zk-SNARKs:
no circuits, no trusted setup, no proving/verification key distinction.
The issuer's `PublicKey` serves all roles.

The tradeoff: BBS+ can only prove "these attributes are signed by this
issuer" with selective disclosure. It cannot prove arbitrary predicates
like "age ≥ 18" without revealing the age. For predicate proofs, you
need a zk-SNARK layer on top — which is what the on-chain Aiken
verifier will eventually provide.
