# On-Chain Status

## Honest State

The on-chain side is not implemented yet in the cryptographic sense.

What exists today:

- a valid Aiken project
- compilable BBS and BLS type definitions
- compilable validator entrypoints
- a generated `plutus.json` blueprint
- an off-chain serializer that emits Plutus `Data` CBOR matching the current `BBSProof` and `RegulatorRegistry` shapes

What does not exist yet:

- the BBS+ pairing check
- disclosed-message reconstruction
- transaction-context replay protection logic
- budget measurement
- Aiken tests for valid and invalid proofs

## Why This Matters

The off-chain library can already generate valid BBS+ signatures and proofs, and it can now serialize them into the Aiken-facing redeemer/datum layout. That removes the contract-shape ambiguity, but the repo still cannot claim end-to-end Cardano support because the validator logic itself is not implemented.

## Next On-Chain Work

The next serious on-chain tasks are:

1. implement generator point derivation
2. implement the core proof verification equation
3. replace the current placeholder nonce check with real transaction-context binding
4. add Aiken unit tests
5. measure execution cost for different attribute counts

Until those are done, any documentation describing on-chain verification as complete would be false.
