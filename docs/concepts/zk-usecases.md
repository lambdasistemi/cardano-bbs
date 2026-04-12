# Use Cases

Concrete scenarios showing the full BBS+ selective disclosure flow,
mapped to the `cardano-bbs` Haskell API.

---

## Phase overview

Every use case follows the same four phases:

```mermaid
graph LR
    P1["1. Key<br/>Generation"]
    P2["2. Credential<br/>Issuance"]
    P3["3. Proof<br/>Generation"]
    P4["4. Verification"]

    P1 --> P2 --> P3 --> P4

    style P1 fill:#f9f,stroke:#333
    style P2 fill:#9ff,stroke:#333
    style P3 fill:#c44,stroke:#333,color:#fff
    style P4 fill:#4a4,stroke:#333,color:#fff
```

| Phase | Who | API call | Frequency |
|-------|-----|----------|-----------|
| 1. Key Generation | Issuer | `generateKeyPair` | Once per issuer |
| 2. Issuance | Issuer → Holder | `issueCredential(sk, pk, header, attributes)` | Once per holder |
| 3. Proof | Holder | `deriveProof(pk, cred, header, ph, attrs, ds)` | Every presentation |
| 4. Verify | Verifier | `verifyProof(pk, header, ph, attrs, ds, proof)` | Every presentation |

---

## Use Case 1: Age verification at a bar

Alice (25) wants to enter a bar. The bar needs to see her age but
must not learn her name, address, or ID number.

### Setup

```haskell
-- Issuer (government) has:
(sk, pk) <- generateKeyPair

-- Credential attributes:
attributes =
  [ Attribute "Alice"    -- index 0: name
  , Attribute "25"       -- index 1: age
  , Attribute "Rome"     -- index 2: address
  , Attribute "XK-472"   -- index 3: id
  ]

-- Issuance (once):
credential <- issueCredential sk pk Nothing attributes
-- Holder stores: credential, attributes, pk
```

### Presentation

```mermaid
sequenceDiagram
    participant Alice as Alice (Holder)
    participant Bar as Bar (Verifier)

    Note over Alice: disclosureSet = [1]<br/>(reveal only index 1 = age)<br/><br/>presentationHeader = fresh nonce<br/><br/>deriveProof(pk, credential,<br/>  Nothing, presentationHeader,<br/>  attributes, [1])

    Alice->>Bar: Disclosed: [Attribute "25"]<br/>DisclosureSet: [1]<br/>PresentationHeader: nonce<br/>Proof: ~304 bytes (opaque)

    Note over Bar: verifyProof(pk, Nothing,<br/>  presentationHeader,<br/>  [Attribute "25"], [1], proof)<br/>→ true ✓<br/><br/>Checks:<br/>  ✓ Credential has ≥ 4 attributes<br/>  ✓ Attribute at index 1 = "25"<br/>  ✓ Signed by pk (government)<br/><br/>Bar sees: age = "25"<br/>Bar does NOT see: name, address, id

    Bar-->>Alice: Entry granted
```

---

## Use Case 2: Address proof for a bank

Alice opens a bank account. The bank needs proof she lives in Rome.
Same credential, different disclosure.

```mermaid
sequenceDiagram
    participant Alice as Alice (Holder)
    participant Bank as Bank (Verifier)

    Note over Alice: SAME credential, SAME attributes<br/><br/>disclosureSet = [2]<br/>(reveal only index 2 = address)<br/><br/>presentationHeader = new nonce<br/><br/>deriveProof(pk, credential,<br/>  Nothing, presentationHeader,<br/>  attributes, [2])

    Alice->>Bank: Disclosed: [Attribute "Rome"]<br/>DisclosureSet: [2]<br/>PresentationHeader: nonce₂<br/>Proof: ~304 bytes

    Note over Bank: verifyProof(pk, Nothing,<br/>  presentationHeader,<br/>  [Attribute "Rome"], [2], proof)<br/>→ true ✓<br/><br/>Bank sees: address = "Rome"<br/>Bank does NOT see: name, age, id

    Bank-->>Alice: Account opened
```

---

## Use Case 3: Unlinkability — bar and bank collude

The bar and the bank compare notes. Can they tell it was the same person?

```mermaid
graph TD
    subgraph "Bar received"
        B1["Disclosed: [Attribute '25']"]
        B2["DisclosureSet: [1]"]
        B3["PresentationHeader: nonce₁"]
        B4["Proof: π₁ (opaque bytes)"]
    end

    subgraph "Bank received"
        K1["Disclosed: [Attribute 'Rome']"]
        K2["DisclosureSet: [2]"]
        K3["PresentationHeader: nonce₂"]
        K4["Proof: π₂ (opaque bytes)"]
    end

    subgraph "Comparison"
        C1["Disclosed values? '25' vs 'Rome' — different ✗"]
        C2["Disclosure indices? [1] vs [2] — different ✗"]
        C3["Presentation headers? nonce₁ vs nonce₂ — different ✗"]
        C4["Proof bytes? π₁ vs π₂ — completely different ✗<br/>(re-randomized signature + different nonce)"]
        C5["Any shared field at all? NO"]
    end

    VERDICT["UNLINKABLE<br/>Cannot determine same holder"]

    B1 --> C1
    K1 --> C1
    B4 --> C4
    K4 --> C4
    C1 --> C5
    C2 --> C5
    C3 --> C5
    C4 --> C5
    C5 --> VERDICT

    style VERDICT fill:#4a4,stroke:#333,color:#fff
```

**Why it works:** The `Credential` (BBS+ signature) is re-randomized
with fresh blinding factors inside `deriveProof`. The `PresentationHeader`
nonce is mixed into the Fiat-Shamir challenge. Together, these ensure
that no stable value appears in both presentations.

---

## Use Case 4: Same disclosure to two bars

Alice visits two bars on the same night. Both require age disclosure.
Same credential, same attributes, same disclosure set — only the
`PresentationHeader` nonce differs.

```mermaid
sequenceDiagram
    participant Alice as Alice
    participant Bar1 as Bar 1
    participant Bar2 as Bar 2

    Note over Alice: deriveProof(pk, credential, Nothing,<br/>  nonce_a, attributes, [1]) → π_a

    Alice->>Bar1: Disclosed: [Attribute "25"]<br/>DisclosureSet: [1]<br/>PresentationHeader: nonce_a<br/>Proof: π_a

    Note over Alice: deriveProof(pk, credential, Nothing,<br/>  nonce_b, attributes, [1]) → π_b

    Alice->>Bar2: Disclosed: [Attribute "25"]<br/>DisclosureSet: [1]<br/>PresentationHeader: nonce_b<br/>Proof: π_b

    Note over Bar1,Bar2: Disclosed values: SAME ("25") ✗<br/>DisclosureSet: SAME ([1]) ✗<br/>PresentationHeader: DIFFERENT ✓<br/>Proof bytes: COMPLETELY DIFFERENT ✓<br/>(different blinding + different nonce)<br/><br/>The only common values are the<br/>disclosed attribute and the set indices —<br/>but those are generic ("age 25 from<br/>the government") and shared by<br/>many credential holders.<br/><br/>The proof bytes are the only<br/>holder-specific data, and they differ.<br/>→ UNLINKABLE
```

!!! warning "Disclosed values can be a soft correlator"
    If the disclosed attribute is highly unique (e.g., a rare name or
    an unusual age), verifiers might guess the same holder. BBS+
    prevents *cryptographic* linkability but cannot prevent
    *statistical* inference from the disclosed values themselves.
    Minimize disclosure to reduce this risk.

---

## Use Case 5: Multiple issuers

Alice has credentials from two issuers:

- **Government** (pk_gov): name, age, address, id
- **University** (pk_uni): name, student_id, degree, gpa

Each credential is signed with a different `SecretKey` and verified
with a different `PublicKey`.

```mermaid
graph TD
    subgraph "Government credential"
        G_ATTRS["Attributes:<br/>[name, age, address, id]"]
        G_CRED["Credential: sign(sk_gov, attributes)"]
        G_PK["Verified with: pk_gov"]
    end

    subgraph "University credential"
        U_ATTRS["Attributes:<br/>[name, student_id, degree, gpa]"]
        U_CRED["Credential: sign(sk_uni, attributes)"]
        U_PK["Verified with: pk_uni"]
    end

    style G_PK fill:#66f,stroke:#333,color:#fff
    style U_PK fill:#fa0,stroke:#333,color:#000
```

```mermaid
sequenceDiagram
    participant Alice as Alice
    participant Employer as Employer

    Note over Employer: Wants: degree from university<br/>Trusts: pk_uni only

    Note over Alice: Uses UNIVERSITY credential:<br/>  deriveProof(pk_uni, uni_credential,<br/>    Nothing, nonce,<br/>    [name, student_id, degree, gpa],<br/>    [2])

    Alice->>Employer: Disclosed: [Attribute "MSc Computer Science"]<br/>DisclosureSet: [2]<br/>PresentationHeader: nonce<br/>Proof: π

    Note over Employer: verifyProof(pk_uni, Nothing,<br/>  nonce, [Attribute "MSc CS"], [2], π)<br/>→ true ✓<br/><br/>Learned: degree = "MSc Computer Science"<br/>  signed by the university<br/>Does NOT know: name, student_id, gpa
```

The verifier decides which `PublicKey` to trust. If Alice presents
a government credential to an employer who only trusts the university,
the employer simply rejects the `PublicKey` — the proof itself would
still be valid, but the trust anchor is wrong.

---

## Use Case 6: Multi-attribute disclosure

Sometimes the verifier needs more than one attribute. The holder
controls exactly which combination to reveal.

```mermaid
sequenceDiagram
    participant Alice as Alice
    participant Landlord as Landlord

    Note over Landlord: Wants: name + address<br/>(to verify tenant identity)

    Note over Alice: disclosureSet = [0, 2]<br/>(reveal name and address)<br/><br/>deriveProof(pk, credential, Nothing,<br/>  nonce, attributes, [0, 2])

    Alice->>Landlord: Disclosed:<br/>  [Attribute "Alice", Attribute "Rome"]<br/>DisclosureSet: [0, 2]<br/>PresentationHeader: nonce<br/>Proof: ~272 bytes (2 hidden, smaller proof)

    Note over Landlord: verifyProof(pk, Nothing,<br/>  nonce,<br/>  [Attribute "Alice", Attribute "Rome"],<br/>  [0, 2], proof)<br/>→ true ✓<br/><br/>Sees: name = "Alice", address = "Rome"<br/>Hidden: age, id
```

Note the proof is smaller (~272 bytes) because fewer attributes are
hidden. The formula:

```
proof_size = 272 + 32 × max(0, total_attributes − disclosed_count)
```

| Disclosed | Hidden | Proof size |
|-----------|--------|-----------|
| 1 of 4 | 3 | 368 bytes |
| 2 of 4 | 2 | 336 bytes |
| 3 of 4 | 1 | 304 bytes |
| 4 of 4 | 0 | 272 bytes |

---

## Use Case 7: On-chain verification (future)

The Aiken on-chain verifier (not yet implemented) will verify BBS+
proofs as part of Cardano transaction validation.

```mermaid
sequenceDiagram
    participant Holder
    participant TxBuilder as Tx Builder (off-chain)
    participant Chain as Cardano Chain

    Holder->>TxBuilder: Proof + disclosed attributes<br/>+ DisclosureSet

    Note over TxBuilder: Serializes proof into<br/>BBSProofDatum:<br/>  { aBar: G1Element<br/>    bBar: G1Element<br/>    d: G1Element<br/>    eHat, r1Hat, r3Hat: Scalar<br/>    mHat: [Scalar] (hidden attrs)<br/>    challenge: Scalar<br/>    disclosedIndices: [Int]<br/>    disclosedValues: [ByteString]<br/>    nonce: ByteString }

    TxBuilder->>Chain: Transaction with<br/>BBSProofDatum in redeemer

    Note over Chain: Aiken validator:<br/>  1. Deserialize BBSProofDatum<br/>  2. Look up PublicKey from<br/>     RegulatorRegistryDatum<br/>  3. Recompute Fiat-Shamir challenge<br/>  4. Check BLS12-381 pairing equation<br/>  5. Accept or reject tx

    Chain-->>Holder: Tx confirmed ✓
```

This enables **privacy-preserving compliance on-chain**: a transaction
can prove a credential fact (e.g., "holder is KYC'd") without revealing
the holder's identity to anyone reading the chain.

---

## Lifecycle summary

```mermaid
graph TD
    subgraph "Once per issuer"
        A1["generateKeyPair<br/>→ (SecretKey, PublicKey)"]
    end

    subgraph "Once per holder"
        B1["issueCredential(sk, pk,<br/>  header, attributes)<br/>→ Credential"]
        B2["Holder stores:<br/>  Credential + attributes + pk"]
        B1 --> B2
    end

    subgraph "Every presentation"
        C1["Holder picks DisclosureSet<br/>+ fresh PresentationHeader"]
        C2["deriveProof(pk, credential,<br/>  header, ph, attributes, ds)<br/>→ Proof"]
        C3["Holder sends:<br/>  disclosed attrs + ds + ph + Proof"]
        C4["verifyProof(pk, header,<br/>  ph, disclosed, ds, proof)<br/>→ Bool"]
        C1 --> C2 --> C3 --> C4
    end

    A1 -->|"pk"| B1
    A1 -->|"sk"| B1
    B2 -->|"credential + attributes"| C2
    A1 -->|"pk"| C4

    style A1 fill:#f9f,stroke:#333
    style B1 fill:#9ff,stroke:#333
    style B2 fill:#9ff,stroke:#333
    style C1 fill:#c44,stroke:#333,color:#fff
    style C2 fill:#c44,stroke:#333,color:#fff
    style C3 fill:#48f,stroke:#333,color:#fff
    style C4 fill:#4a4,stroke:#333,color:#fff
```
