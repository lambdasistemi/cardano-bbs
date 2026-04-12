/-
  # ZK Proofs for Selective Disclosure
  Lean 4 specification of all data structures and operations.
  Cryptographic primitives are axiomatized.
-/

-- ============================================================
-- Cryptographic primitives (axiomatized)
-- ============================================================

/-- Digital signature over some data -/
axiom Signature : Type
/-- Cryptographic randomness, freshly sampled each time -/
axiom Randomness : Type
/-- Secret signing key — only the issuer holds this -/
axiom SecretKey : Type
/-- Public verification key — anyone can hold this -/
axiom PublicKey : Type

/-- Sign arbitrary data with a secret key -/
axiom sign : {α : Type} → SecretKey → α → Signature
/-- Verify a signature against a public key and the signed data -/
axiom verifySig : {α : Type} → PublicKey → α → Signature → Bool

-- ============================================================
-- Credential: the attributes an issuer certifies about a holder
-- ============================================================

/-- A credential is a fixed set of named attributes.
    In a real system this would be extensible; here we fix four
    fields for concreteness. -/
structure Credential where
  name    : String
  age     : Nat
  address : String
  id      : String

-- ============================================================
-- Issuance: what the issuer gives the holder
-- ============================================================

/-- The holder's private data bundle. Produced by the issuer at
    credential issuance time. NEVER transmitted after that —
    it is the "witness" for all future ZK proofs. -/
structure CredentialWitness where
  credential : Credential   -- all attribute values in cleartext
  issuerSig  : Signature    -- sign(issuer.sk, credential)

/-- Issuer creates a CredentialWitness and hands it to the holder.
    After this, the issuer plays no further role. -/
noncomputable def issueCredential (sk : SecretKey) (c : Credential)
    : CredentialWitness :=
  { credential := c
    issuerSig  := sign sk c }

-- ============================================================
-- Circuits: public programs that define provable claims
-- ============================================================

/-
  A Circuit is a public, deterministic program compiled into
  arithmetic constraints over a finite field.

  It takes two inputs:
    • pubInputs — values the verifier can see (the "statement")
    • witness   — values only the prover knows (the "secret")

  and evaluates to true iff the claimed relationship holds.

  Everyone — issuer, holder, verifier — agrees on which circuit
  is used. Think of it as a "claim template":

    "There exist private attributes and a valid issuer signature
     such that ⟨some predicate on the attributes⟩ holds."

  Different predicates need different circuits.
-/

/-- A compiled arithmetic circuit, parametrized by the types
    of public inputs and private witness. -/
axiom Circuit : (pubInputs : Type) → (witness : Type) → Type

-- ============================================================
-- Trusted setup: derives per-circuit keys
-- ============================================================

/-
  Before any proofs can be created for a circuit, a one-time
  trusted setup ceremony must run. It consumes the circuit
  definition plus randomness from a multi-party ceremony
  (no single party learns the full randomness) and produces:

    • ProvingKey   — large (~MBs), used by the holder to create proofs
    • VerificationKey — small (~bytes), used by any verifier to check proofs

  Both keys are PUBLIC. Neither is secret.
  They are bound to a specific circuit — you cannot use the
  proving key of one circuit to create proofs for another.
-/

/-- Proving key, derived from a specific Circuit during trusted setup.
    Large (~MBs). The holder needs this to call `prove`. PUBLIC. -/
axiom ProvingKey : (pubInputs : Type) → (witness : Type) → Type

/-- Verification key, derived from the same Circuit during trusted setup.
    Small (~bytes). Any verifier needs this to call `verify`. PUBLIC. -/
axiom VerificationKey : (pubInputs : Type) → (witness : Type) → Type

/-- The paired output of a trusted setup ceremony. -/
structure SetupResult (pubInputs witness : Type) where
  provingKey : ProvingKey pubInputs witness
  verifyKey  : VerificationKey pubInputs witness

-- ============================================================
-- Ceremony internals: how trustedSetup is implemented
-- ============================================================

/-- An element of the finite field 𝔽ₚ -/
axiom FieldElement : Type
/-- A point on the elliptic curve -/
axiom CurvePoint : Type
/-- The generator point of the curve -/
axiom G₁ : CurvePoint
/-- Scalar multiplication: [s]P -/
axiom scalarMul : FieldElement → CurvePoint → CurvePoint
/-- Field multiplication -/
axiom fieldMul : FieldElement → FieldElement → FieldElement
/-- Exponentiation in the field: s^i -/
axiom fieldPow : FieldElement → Nat → FieldElement
/-- Sample a random field element from randomness -/
axiom sampleField : Randomness → FieldElement

/-- The Structured Reference String: encoded powers of τ on the curve.
    Nobody knows τ — only these curve points exist. -/
structure SRS where
  degree : Nat                     -- circuit degree
  powersG1 : List CurvePoint      -- [τ⁰]G₁, [τ¹]G₁, …, [τᵈ]G₁
  powersG2 : List CurvePoint      -- [τ⁰]G₂, [τ¹]G₂, …, [τᵈ]G₂

/-- A participant's contribution: the transformed SRS + proof they
    actually used a secret (not just forwarded the input). -/
structure CeremonyContribution where
  srs              : SRS           -- the updated SRS
  proofOfKnowledge : CurvePoint    -- [sₖ]G₁ — proves participant knew sₖ

/-- One participant's step: receive SRS, mix in secret, output new SRS.
    The secret sₖ exists only during this function call. -/
noncomputable def participantStep (prev : SRS) (rand : Randomness) : CeremonyContribution :=
  let sₖ := sampleField rand
  let newPowersG1 := prev.powersG1.map fun pt => scalarMul sₖ pt
  let newPowersG2 := prev.powersG2.map fun pt => scalarMul sₖ pt
  { srs := { degree := prev.degree, powersG1 := newPowersG1, powersG2 := newPowersG2 }
    proofOfKnowledge := scalarMul sₖ G₁ }
  -- sₖ goes out of scope here and must be destroyed

/-- Run the full ceremony: fold over all participants' randomness. -/
noncomputable def ceremony (degree : Nat) (participants : List Randomness) : SRS :=
  let identity : SRS :=
    { degree
      powersG1 := (List.range (degree + 1)).map fun _ => G₁
      powersG2 := (List.range (degree + 1)).map fun _ => G₁ }
  participants.foldl (fun srs rand => (participantStep srs rand).srs) identity

/-- Deterministic key derivation from SRS + circuit (no secrets needed). -/
axiom deriveKeys : {pubInputs witness : Type} →
  SRS → Circuit pubInputs witness → SetupResult pubInputs witness

/-- Trusted setup: run once per circuit. -/
axiom trustedSetup : {pubInputs witness : Type} →
  Circuit pubInputs witness → Randomness → SetupResult pubInputs witness

-- ============================================================
-- Proof: the opaque output of the prover
-- ============================================================

/-
  A Proof is an opaque blob (~256 bytes). It carries NO
  information about the witness — not the credential values,
  not the issuer signature, nothing.

  Crucially, each proof incorporates fresh Randomness, so two
  proofs for the same witness and the same public inputs are
  completely different byte strings. This is what makes
  presentations unlinkable.
-/

/-- An opaque ZK proof, parametrized only by the public input type.
    The witness type does not appear — it is fully hidden. -/
axiom Proof : (pubInputs : Type) → Type

-- ============================================================
-- prove / verify: the two core operations
-- ============================================================

/-- The prover (holder) calls this.
    Inputs:
      • ProvingKey — from the circuit registry (public)
      • pubInputs  — the statement, e.g. {threshold := 18, issuerPk}
      • witness    — the secret, e.g. CredentialWitness
      • Randomness — freshly sampled, makes each proof unique
    Output:
      • Proof pubInputs — opaque bytes
    The Randomness ensures that calling prove twice with the
    same witness and public inputs yields different proofs. -/
axiom prove : {pubInputs witness : Type} →
  ProvingKey pubInputs witness →
  pubInputs →
  witness →
  Randomness →
  Proof pubInputs

/-- The verifier calls this.
    Inputs:
      • VerificationKey — from the circuit registry (public)
      • pubInputs       — the statement the holder claims
      • Proof           — the opaque blob from the holder
    Output:
      • Bool — true iff the proof is valid
    The verifier NEVER receives or touches the witness. -/
axiom verify : {pubInputs witness : Type} →
  VerificationKey pubInputs witness →
  pubInputs →
  Proof pubInputs →
  Bool

-- ============================================================
-- Concrete circuits for selective disclosure
-- ============================================================

/-- Public inputs for "age ≥ threshold".
    This is what the verifier sees — the threshold and which
    issuer to trust. The actual age stays hidden in the witness. -/
structure AgeThresholdPublic where
  threshold : Nat        -- e.g. 18
  issuerPk  : PublicKey  -- which issuer's credentials to accept

/-- The age-threshold circuit checks (conceptually):
      verifySig(pub.issuerPk, wit.credential, wit.issuerSig)
      ∧ wit.credential.age ≥ pub.threshold
    The actual implementation is compiled arithmetic gates. -/
axiom ageThresholdCircuit : Circuit AgeThresholdPublic CredentialWitness

/-- Public inputs for "address = city". -/
structure AddressEqualsPublic where
  city     : String      -- e.g. "Rome"
  issuerPk : PublicKey

/-- The address-equality circuit checks:
      verifySig(pub.issuerPk, wit.credential, wit.issuerSig)
      ∧ wit.credential.address = pub.city -/
axiom addressEqualsCircuit : Circuit AddressEqualsPublic CredentialWitness

-- ============================================================
-- Circuit registry: how verifiers find the right key
-- ============================================================

/-
  In practice circuits are published by a standards body or issuer.
  Each circuit gets a string identifier. Verifiers look up the
  VerificationKey by this identifier.

  The registry is a heterogeneous collection — each entry may have
  different pubInputs/witness types. We model one entry at a time.
-/

/-- A typed registry entry: bundles a circuit with its ID and keys. -/
structure TypedCircuitEntry (pubInputs witness : Type) where
  circuitId   : String
  description : String
  circuit     : Circuit pubInputs witness
  setup       : SetupResult pubInputs witness

noncomputable def ageCircuitEntry
    (setup : SetupResult AgeThresholdPublic CredentialWitness)
    : TypedCircuitEntry AgeThresholdPublic CredentialWitness :=
  { circuitId   := "age-threshold-v1"
    description := "age ≥ threshold with issuer signature check"
    circuit     := ageThresholdCircuit
    setup       := setup }

noncomputable def addressCircuitEntry
    (setup : SetupResult AddressEqualsPublic CredentialWitness)
    : TypedCircuitEntry AddressEqualsPublic CredentialWitness :=
  { circuitId   := "address-equals-v1"
    description := "address = city with issuer signature check"
    circuit     := addressEqualsCircuit
    setup       := setup }

-- ============================================================
-- ZK Presentation: the message from holder to verifier
-- ============================================================

/-- What the holder actually sends to a verifier.
    Contains NO credential data, NO issuer signature — only:
      • which circuit was used (so verifier can look up the key)
      • the public inputs (the claim being made)
      • the opaque proof -/
structure ZkPresentation (pubInputs : Type) where
  circuitId    : String
  publicInputs : pubInputs
  proof        : Proof pubInputs

-- ============================================================
-- Protocol operations
-- ============================================================

/-- Holder builds a presentation for "age ≥ threshold".
    Consumes fresh Randomness to ensure unlinkability. -/
noncomputable def presentAgeThreshold
    (entry : TypedCircuitEntry AgeThresholdPublic CredentialWitness)
    (witness : CredentialWitness)
    (threshold : Nat)
    (issuerPk : PublicKey)
    (rand : Randomness)
    : ZkPresentation AgeThresholdPublic :=
  let pub : AgeThresholdPublic := { threshold, issuerPk }
  { circuitId    := entry.circuitId
    publicInputs := pub
    proof        := prove entry.setup.provingKey pub witness rand }

/-- Holder builds a presentation for "address = city". -/
noncomputable def presentAddressEquals
    (entry : TypedCircuitEntry AddressEqualsPublic CredentialWitness)
    (witness : CredentialWitness)
    (city : String)
    (issuerPk : PublicKey)
    (rand : Randomness)
    : ZkPresentation AddressEqualsPublic :=
  let pub : AddressEqualsPublic := { city, issuerPk }
  { circuitId    := entry.circuitId
    publicInputs := pub
    proof        := prove entry.setup.provingKey pub witness rand }

/-- Verifier checks a presentation against a registry entry. -/
noncomputable def zkVerify
    {pubInputs witness : Type}
    (entry : TypedCircuitEntry pubInputs witness)
    (pres : ZkPresentation pubInputs)
    : Bool :=
  entry.circuitId == pres.circuitId
  && verify entry.setup.verifyKey pres.publicInputs pres.proof

-- ============================================================
-- Full scenario: two verifiers, no linkability
-- ============================================================

noncomputable def exampleFlow
    (issuerSk : SecretKey)
    (issuerPk : PublicKey)
    (setupAge : SetupResult AgeThresholdPublic CredentialWitness)
    (setupAddr : SetupResult AddressEqualsPublic CredentialWitness)
    (rand1 rand2 : Randomness)
    : Bool × Bool :=
  -- Issuer creates credential
  let witness := issueCredential issuerSk
    { name := "Alice", age := 25, address := "Rome", id := "XK-472" }

  let entryAge := ageCircuitEntry setupAge
  let entryAddr := addressCircuitEntry setupAddr

  -- Holder → Verifier A: "my age ≥ 18"
  let presA := presentAgeThreshold entryAge witness 18 issuerPk rand1

  -- Holder → Verifier B: "my address = Rome"
  let presB := presentAddressEquals entryAddr witness "Rome" issuerPk rand2

  -- Each verifier checks independently
  let resultA := zkVerify entryAge presA
  let resultB := zkVerify entryAddr presB

  -- presA and presB share NO data:
  --   presA.proof ≠ presB.proof          (different Randomness)
  --   presA.circuitId ≠ presB.circuitId  (different circuits)
  --   presA.publicInputs and presB.publicInputs have different types
  -- Verifier A and B cannot determine they dealt with the same holder.
  (resultA, resultB)
