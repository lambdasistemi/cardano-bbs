# On-Chain API Contract (Aiken Validators)

## BBS+ Proof Verifier

### Datum (reference input)

```
RegulatorRegistry {
  regulator_pk: G2Element,
  credential_schema: List<ByteArray>,
  signed_header: ByteArray,
}
```

### Redeemer

```
BBSProof {
  a_bar: G1Element,
  b_bar: G1Element,
  d: G1Element,
  e_hat: ByteArray,       -- scalar, 32 bytes big-endian
  r1_hat: ByteArray,
  r3_hat: ByteArray,
  m_hat: List<ByteArray>, -- one per undisclosed attribute
  c: ByteArray,
  disclosed_indices: List<Int>,
  disclosed_values: List<ByteArray>,
  nonce: ByteArray,
}
```

### Verification Logic

1. Reconstruct point B from disclosed messages and generators
2. Compute Fiat-Shamir challenge, compare with `c`
   using the regulator datum's `signed_header` in the domain calculation
3. Check pairing: `final_exponentiation(miller_loop(a_bar, regulator_pk), miller_loop(b_bar, neg_g2))`
4. Verify nonce binds to current transaction context

## BLS Aggregate Signature Verifier

### Datum

```
OracleRegistry {
  oracle_pks: List<G2Element>,
  quorum: Int,
}
```

### Redeemer

```
AggregateSignatureRedeemer {
  signature: G1Element,
  message: ByteArray,
  signer_indices: List<Int>,  -- which registered oracles signed
}
```

### Verification Logic

1. Check `length(signer_indices) >= quorum`
2. Sum public keys: `pk_agg = sum(oracle_pks[i] for i in signer_indices)`
3. Hash message to G1: `h = g1.hash_to_group(message, dst)`
4. Check pairing: `final_exponentiation(miller_loop(signature, g2_generator), miller_loop(h, pk_agg))`
