# Quickstart: BBS+ Credentials

## Prerequisites

- Nix (with flakes enabled)
- Aiken CLI (provided via nix develop shell)

## Build

```bash
nix develop
just build        # builds both offchain (Haskell) and onchain (Aiken)
```

## Run Tests

```bash
just test         # unit + conformance tests
just test-round-trip  # off-chain → on-chain integration
```

## Usage Flow

### 1. Regulator issues a credential

```haskell
(sk, pk) <- generateKeyPair
let attributes = [attr "jurisdiction" "EU", attr "role" "controller"]
credential <- issueCredential sk attributes
-- give credential to user, publish pk on-chain
```

### 2. User derives a proof

```haskell
let disclose = disclosureSet [0]  -- reveal "jurisdiction", hide "role"
let nonce = txContextNonce txBody
proof <- deriveProof credential disclose nonce
let redeemer = proofToCBOR proof
-- submit transaction with redeemer
```

### 3. On-chain validator checks

The Aiken validator reads `regulator_pk` from a reference input and verifies the BBS+ proof in the redeemer. If valid, the transaction succeeds.

### 4. Multi-oracle BLS aggregation

```haskell
-- each oracle signs independently
sig1 <- blsSign oracleSk1 merkleRoot
sig2 <- blsSign oracleSk2 merkleRoot
sig3 <- blsSign oracleSk3 merkleRoot

-- anyone aggregates
let aggSig = blsAggregate [sig1, sig2, sig3]
let redeemer = aggregateSigToCBOR aggSig
-- submit update transaction
```
