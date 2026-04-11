# Data Model: BBS+ Credentials

## Entities

### SignerKeyPair

The regulator/identity provider's key material.

| Field | Type | Description |
|---|---|---|
| secret_key | Scalar | BLS12-381 scalar field element |
| public_key | G2Element | Corresponding G2 point, published on-chain |

### Credential

A BBS+ signature over an ordered list of attributes, held by the user.

| Field | Type | Description |
|---|---|---|
| signature_A | G1Element | Signature point (48 bytes compressed) |
| signature_e | Scalar | Signature scalar (32 bytes) |
| attributes | [Scalar] | Ordered list of signed attributes |
| signer_pk | G2Element | Public key of the issuing regulator |

**Invariant**: `verify(signer_pk, attributes, (signature_A, signature_e)) == true`

### Proof

A zero-knowledge derivation from a credential, submitted as a redeemer.

| Field | Type | Description |
|---|---|---|
| Abar | G1Element | Randomized signature component |
| Bbar | G1Element | Randomized signature component |
| D | G1Element | Blinding factor commitment |
| e_hat | Scalar | Schnorr response for signature scalar |
| r1_hat | Scalar | Schnorr response for blinding factor 1 |
| r3_hat | Scalar | Schnorr response for blinding factor 2 |
| m_hat | [Scalar] | Schnorr responses for undisclosed attributes (one per hidden attribute) |
| c | Scalar | Fiat-Shamir challenge |
| disclosed_indices | [Int] | Which attribute positions are revealed |
| disclosed_values | [Scalar] | Values of disclosed attributes |
| nonce | ByteArray | Transaction-binding context (prevents replay) |

**Size**: 272 + 32·U bytes (U = number of undisclosed attributes)

### AggregateSignature (BLS)

For multi-oracle use case.

| Field | Type | Description |
|---|---|---|
| signature | G1Element | Aggregated BLS signature (48 bytes) |
| message | ByteArray | The signed message (e.g., Merkle root hash) |
| signer_pks | [G2Element] | Public keys of participating oracles |

**Invariant**: `e(signature, G2_gen) == e(H(message), sum(signer_pks))`

### OracleRegistry (on-chain datum)

| Field | Type | Description |
|---|---|---|
| oracle_pks | [G2Element] | Registered oracle public keys |
| quorum | Int | Minimum number of signers required |

### RegulatorRegistry (on-chain datum)

| Field | Type | Description |
|---|---|---|
| regulator_pk | G2Element | Regulator's BBS+ public key |
| credential_schema | [ByteArray] | Attribute names/types for validation context |

## Relationships

```
SignerKeyPair --issues--> Credential --derives--> Proof
                                                    |
RegulatorRegistry --validates-against-------------- +
                                                    |
OracleRegistry --validates-against-- AggregateSignature
```

## State Transitions

### Credential Lifecycle

```
NonExistent → Issued → [Active | Revoked]
```

- `Issued`: regulator signs attributes, user receives credential
- `Active`: user can derive proofs
- `Revoked`: proofs from this credential are rejected (P3, deferred)

### Proof Lifecycle

```
Derived → Submitted → Verified | Rejected
```

- `Derived`: user creates proof off-chain
- `Submitted`: included as redeemer in transaction
- `Verified`: on-chain validator accepts
- `Rejected`: on-chain validator rejects (invalid proof, wrong regulator, replay)

## Validation Rules

- A proof MUST bind to a specific transaction context (nonce) to prevent replay
- A proof's disclosed_indices MUST be a valid subset of [0..N-1] where N is the credential's attribute count
- The on-chain validator MUST check the proof against the regulator_pk from a reference input
- For BLS aggregation, the number of signer_pks MUST be >= quorum from OracleRegistry
