# On-Chain Status

## Honest State

The on-chain side now implements the core BBS verifier for the current credential flow.

What exists today:

- a valid Aiken project
- compilable BBS and BLS type definitions
- compilable validator entrypoints
- a generated `plutus.json` blueprint
- an off-chain serializer that emits Plutus `Data` CBOR matching the current `BBSProof` and `RegulatorRegistry` shapes
- deterministic SHA-256 ciphersuite generator derivation for `Q_1` and message generators, matching the current IETF BBS draft vectors
- BBS proof validation on-chain, including:
  - regulator/public proof byte-size checks
  - disclosure-count and disclosure-index validation
  - transaction-context nonce checking against the consumed script `OutputReference`
  - Fiat-Shamir transcript recomputation for both empty and non-empty signed-header flows:
    - message-to-scalar hashing
    - domain derivation
    - challenge recomputation from `Abar`, `Bbar`, `D`, `T1`, `T2`
  - the core BBS pairing equation:
    - `e(Abar, W) == e(Bbar, BP2)`
- Aiken tests covering verifier acceptance and rejection paths
- a local `cardano-node-clients` submitted-transaction slice exercising the validator against a real devnet node

What does not exist yet:

- a public Cardano testnet submission flow beyond the local `cardano-node-clients` devnet
- the separate BLS aggregation track

## Why This Matters

The off-chain library can already generate valid BBS+ signatures and proofs, serialize them into the Aiken-facing redeemer and datum layout, carry the credential signed header into the on-chain domain calculation, and submit a real validator spend on a local devnet through `cardano-node-clients`. The current on-chain verifier is no longer a structural stub: it recomputes the transcript challenge, checks the core pairing equation, and stays within the 10B CPU transaction ceiling for the measured 1, 5, and 10 attribute cases.

## Current Budget Signal

Measured verifier costs are now documented in [budget-report.md](/code/cardano-bbs-verify/specs/001-bbs-credentials/budget-report.md).

- 1 attribute: `2.81B` CPU
- 5 attributes: `4.31B` CPU
- 10 attributes: `6.26B` CPU

The important result is that the verifier remains under the 10B CPU transaction budget for the currently measured cases. The budget suite still uses `signed_header = ""`, so the next measurement pass should quantify any cost delta for non-empty headers.

## Next On-Chain Work

The next serious on-chain tasks are:

1. re-measure the verifier with non-empty signed headers in [budget.ak](/code/cardano-bbs-verify/onchain/lib/bbs/budget.ak)
2. extend the local devnet transaction slice into a public Cardano testnet run
3. split the current embedded Aiken tests into a cleaner structure once the toolchain supports dedicated test modules reliably
4. build the separate BLS aggregation track

Until those are done, any documentation describing the Cardano integration story as fully complete would be false.
