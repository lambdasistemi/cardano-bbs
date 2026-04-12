# Trusted Setup Ceremony

How zk-SNARK systems produce their proving and verification keys
without anyone learning the secret that would allow forging proofs.

!!! info "BBS+ does NOT need a ceremony"
    The BBS+ scheme used in `cardano-bbs` works with direct key
    generation (`generateKeyPair`). No ceremony is required.

    This page documents the ceremony concept because:

    - The future on-chain verifier may use zk-SNARKs for predicate
      proofs ("age ≥ 18") on top of BBS+ disclosed attributes
    - Understanding the ceremony clarifies the broader ZK landscape
    - It explains a key advantage of BBS+: simpler trust assumptions

---

## Why some ZK systems need a ceremony

zk-SNARKs (Groth16, PLONK) require a **Structured Reference String
(SRS)** — encoded powers of a secret value τ on an elliptic curve:

```
[τ⁰]G,  [τ¹]G,  [τ²]G,  …,  [τᵈ]G
```

Whoever knows τ can forge proofs for any statement. The ceremony
ensures τ is collectively constructed such that **no single party**
(and no colluding subset short of all parties) ever learns it.

```mermaid
graph TD
    TAU["τ = s₁ · s₂ · s₃ · … · sₙ<br/>(product of all participants' secrets)"]
    FORGE["If ANY party learns τ:<br/>can forge proofs for false statements"]
    SAFE["If AT LEAST ONE party<br/>destroys their sᵢ:<br/>τ is unrecoverable<br/>→ system is sound"]

    TAU --> FORGE
    TAU --> SAFE

    style FORGE fill:#c44,stroke:#333,color:#fff
    style SAFE fill:#4a4,stroke:#333,color:#fff
```

---

## The ceremony protocol

The ceremony is sequential. Each participant takes the previous
output, mixes in their own secret, and passes it forward.

### Participants

| Role | Who | What they do |
|------|-----|-------------|
| Coordinator | A server or smart contract | Sequences contributions, publishes results |
| Participant 1…N | Anyone — researchers, companies, volunteers | Each contributes one secret sᵢ |
| Observers | Anyone | Verify each contribution is well-formed |

No participant trusts any other. The coordinator is **not trusted** —
it only sequences contributions.

### Step by step

```mermaid
sequenceDiagram
    participant Coord as Coordinator
    participant P1 as Participant 1
    participant P2 as Participant 2
    participant P3 as Participant 3
    participant Pub as Public Transcript

    Note over Coord: Initializes:<br/>SRS₀ = { [1]G, [1]G, …, [1]G }

    Coord->>P1: SRS₀

    Note over P1: 1. Sample random s₁ ∈ 𝔽ₚ<br/>2. For each i: SRS₁[i] = [s₁ⁱ] · SRS₀[i]<br/>   = [s₁ⁱ]G<br/>3. Publish proof-of-knowledge of s₁<br/>4. DESTROY s₁

    P1->>Coord: SRS₁ + proof-of-knowledge
    P1->>Pub: Transcript: SRS₀ → SRS₁ + proof

    Coord->>P2: SRS₁

    Note over P2: 1. Sample random s₂ ∈ 𝔽ₚ<br/>2. SRS₂[i] = [s₂ⁱ] · SRS₁[i]<br/>   = [(s₁·s₂)ⁱ]G<br/>3. Proof-of-knowledge of s₂<br/>4. DESTROY s₂

    P2->>Coord: SRS₂ + proof-of-knowledge
    P2->>Pub: Transcript: SRS₁ → SRS₂ + proof

    Coord->>P3: SRS₂

    Note over P3: 1. Sample random s₃ ∈ 𝔽ₚ<br/>2. SRS₃[i] = [s₃ⁱ] · SRS₂[i]<br/>   = [(s₁·s₂·s₃)ⁱ]G<br/>3. Proof-of-knowledge of s₃<br/>4. DESTROY s₃

    P3->>Coord: SRS₃ + proof-of-knowledge
    P3->>Pub: Transcript: SRS₂ → SRS₃ + proof

    Note over Coord: Final SRS = SRS₃<br/>τ = s₁·s₂·s₃<br/><br/>Nobody knows τ:<br/>  P1 knows s₁ but not s₂·s₃<br/>  P2 knows s₂ but not s₁·s₃<br/>  P3 knows s₃ but not s₁·s₂<br/>  Coord never saw any sᵢ

    Coord->>Pub: Final SRS
```

### What each participant computes

```mermaid
graph TD
    subgraph "Participant k receives SRS_{k-1}"
        IN["SRS_{k-1}[i] = [τ_{k-1}ⁱ]G<br/>where τ_{k-1} = s₁·…·s_{k-1}"]
    end

    subgraph "Participant k's computation"
        S["1. Sample sₖ ∈ 𝔽ₚ<br/>(random, in RAM only)"]
        MUL["2. For i = 0 to d:<br/>  SRSₖ[i] = [sₖⁱ] · SRS_{k-1}[i]<br/>  = [(sₖ · τ_{k-1})ⁱ]G"]
        POK["3. Publish [sₖ]G₁ and [sₖ]G₂<br/>(proof of knowledge)"]
        DEL["4. DESTROY sₖ"]
        S --> MUL --> POK --> DEL
    end

    subgraph "Output"
        OUT["SRSₖ[i] = [τₖⁱ]G<br/>where τₖ = s₁·…·sₖ"]
    end

    IN --> MUL
    DEL --> OUT

    style S fill:#c44,stroke:#333,color:#fff
    style DEL fill:#c44,stroke:#333,color:#fff
```

---

## Verification by observers

Anyone can verify the ceremony after the fact:

```mermaid
graph TD
    subgraph "For each transition SRS_{k-1} → SRSₖ"
        V1["1. Pairing check<br/>e([sₖ]G₁, G₂) = e(G₁, [sₖ]G₂)<br/>→ same sₖ used for both curves"]
        V2["2. Consistency check<br/>SRSₖ has valid structure<br/>(powers of a single τₖ)"]
        V3["3. Non-triviality check<br/>SRSₖ ≠ SRS_{k-1}<br/>→ participant actually contributed"]
    end

    V1 --> V2 --> V3

    RESULT["All checks pass ∀ k:<br/>SRS encodes powers of τ = s₁·…·sₙ<br/>and nobody knows τ"]

    V3 --> RESULT

    style RESULT fill:#4a4,stroke:#333,color:#fff
```

---

## From SRS to keys

The SRS is circuit-independent. To get circuit-specific keys, a
deterministic transformation combines the SRS with the circuit:

```mermaid
graph LR
    SRS["SRS<br/>[τ⁰]G, …, [τᵈ]G<br/>(from ceremony)"]
    CIRCUIT["Circuit<br/>(constraint system)"]
    DERIVE["Deterministic<br/>derivation"]
    PK["ProvingKey<br/>(large, holder uses)"]
    VK["VerificationKey<br/>(small, verifier uses)"]

    SRS --> DERIVE
    CIRCUIT --> DERIVE
    DERIVE --> PK
    DERIVE --> VK

    style SRS fill:#fa0,stroke:#333,color:#000
    style PK fill:#c44,stroke:#333,color:#fff
    style VK fill:#4a4,stroke:#333,color:#fff
```

This step is **deterministic and public** — no secrets, no ceremony.

---

## What can go wrong

| Threat | Outcome | Mitigation |
|--------|---------|-----------|
| ALL participants collude | Can reconstruct τ, forge proofs | Run ceremony with hundreds+ participants |
| Coordinator tampers | Detected by transcript verification | Public transcript, anyone can verify |
| Participant uses sᵢ = 1 | Proof-of-knowledge fails | Checked by observers |
| Participant drops out | Ceremony continues | Security unaffected |

---

## Universal vs. circuit-specific setup

```mermaid
graph TD
    subgraph "Circuit-specific (Groth16)"
        CS1["New circuit → new ceremony"]
        CS2["Smaller proofs (~128 bytes)"]
        CS3["Faster verification"]
    end

    subgraph "Universal (PLONK, Marlin)"
        US["ONE ceremony for all circuits"]
        D["New circuit → deterministic key derivation"]
        US --> D
    end

    style CS1 fill:#c44,stroke:#333,color:#fff
    style US fill:#4a4,stroke:#333,color:#fff
```

---

## Transparent setup (no ceremony)

Some systems eliminate the ceremony entirely:

| | SNARKs (ceremony) | STARKs (transparent) | BBS+ |
|---|---|---|---|
| Setup | Multi-party ceremony | None (hash params) | None (direct keygen) |
| Trust | 1-of-N honest | Hash collision-resistance | Issuer key authenticity |
| Proof size | ~128–256 bytes | ~50–200 KB | ~300 bytes |
| Verification | Fast (pairings) | Slower (hash chains) | Fast (pairings) |
| Predicate proofs | Yes (any circuit) | Yes (any circuit) | No (disclosure only) |
| Post-quantum | No | Yes | No |

BBS+ sits in a sweet spot for selective disclosure: no ceremony,
small proofs, fast verification — but limited to "reveal or hide"
decisions on signed attributes. For arbitrary predicates ("age ≥ 18"
without revealing age), a SNARK layer is needed on top.
