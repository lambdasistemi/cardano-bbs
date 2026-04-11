# On-Chain Status

## Honest State

The on-chain side is not implemented yet in the cryptographic sense.

What exists today:

- a valid Aiken project
- compilable BBS and BLS type definitions
- compilable validator entrypoints
- a generated `plutus.json` blueprint
- an off-chain serializer that emits Plutus `Data` CBOR matching the current `BBSProof` and `RegulatorRegistry` shapes
- deterministic SHA-256 ciphersuite generator derivation for `Q_1` and message generators, matching the current IETF BBS draft vectors
- structural BBS proof validation on-chain:
  - regulator/public proof byte-size checks
  - disclosure-count and disclosure-index validation
  - transaction-bound nonce checking against `self.id`
  - Fiat-Shamir transcript recomputation for the current no-header proof flow:
    - message-to-scalar hashing
    - domain derivation
    - challenge recomputation from `Abar`, `Bbar`, `D`, `T1`, `T2`
- Aiken tests covering verifier acceptance and rejection paths

What does not exist yet:

- the BBS+ pairing check
- general signed-header support in the on-chain challenge path
- budget measurement

## Why This Matters

The off-chain library can already generate valid BBS+ signatures and proofs, and it can now serialize them into the Aiken-facing redeemer/datum layout. This slice adds a real rejection gate on-chain instead of unconditional acceptance, and it now recomputes the transcript challenge for the current no-header proof layout. The repo still cannot claim end-to-end Cardano support because the final cryptographic pairing verifier itself is not implemented yet.

## Next On-Chain Work

The next serious on-chain tasks are:

1. use the derived generators inside the real proof verification equation
2. implement the core proof verification equation
3. carry the signed header into the on-chain verification inputs so transcript recomputation matches the full BBS spec
4. measure execution cost for different attribute counts
5. add round-trip integration from off-chain proof generation into Aiken verification assumptions

Until those are done, any documentation describing on-chain verification as complete would be false.
