# On-Chain Status

## Honest State

The on-chain side is not implemented yet in the cryptographic sense.

What exists today:

- a valid Aiken project
- compilable BBS and BLS type definitions
- compilable validator entrypoints
- a generated `plutus.json` blueprint

What does not exist yet:

- the BBS+ pairing check
- disclosed-message reconstruction
- transaction-context replay protection logic
- budget measurement
- Aiken tests for valid and invalid proofs

## Why This Matters

The off-chain library can already generate valid BBS+ signatures and proofs, but the repo cannot yet claim end-to-end Cardano support. The current on-chain modules are placeholders that keep the structure stable while the off-chain foundation matures.

## Next On-Chain Work

The next serious on-chain tasks are:

1. implement generator point derivation
2. implement the core proof verification equation
3. bind the proof nonce to transaction context
4. add Aiken unit tests
5. measure execution cost for different attribute counts

Until those are done, any documentation describing on-chain verification as complete would be false.
