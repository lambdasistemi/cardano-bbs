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
  - the core BBS pairing equation:
    - `e(Abar, W) == e(Bbar, BP2)`
- Aiken tests covering verifier acceptance and rejection paths

What does not exist yet:

- general signed-header support in the on-chain challenge path

## Why This Matters

The off-chain library can already generate valid BBS+ signatures and proofs, and it can now serialize them into the Aiken-facing redeemer/datum layout. The current on-chain verifier adds a real rejection gate instead of unconditional acceptance, recomputes the transcript challenge for the current no-header proof layout, checks the core pairing equation, and now stays within the 10B CPU transaction ceiling for the measured 1, 5, and 10 attribute cases.

## Current Budget Signal

Measured verifier costs are now documented in [budget-report.md](/code/cardano-bbs-verify/specs/001-bbs-credentials/budget-report.md).

- 1 attribute: `2.81B` CPU
- 5 attributes: `4.31B` CPU
- 10 attributes: `6.26B` CPU

The important result is that the current no-header verifier is now under the 10B CPU transaction budget even at 10 attributes.

## Next On-Chain Work

The next serious on-chain tasks are:

1. carry the signed header into the on-chain verification inputs so transcript recomputation matches the full BBS spec
2. preserve the current selective-disclosure and budget envelope while adding signed-header support
3. split the current embedded Aiken tests into a cleaner structure once the toolchain supports dedicated test modules reliably

Until those are done, any documentation describing on-chain verification as fully complete would be false.
