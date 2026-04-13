# Testing

## Current Test Coverage

The current coverage spans imported cryptographic fixtures, off-chain API checks, a real off-chain to on-chain round-trip, and a local devnet submitted-transaction integration test through `cardano-node-clients`.

### Unit tests

- issue a credential and verify it
- reject a tampered attribute set
- derive a selective disclosure proof and verify it
- generate a proof off-chain, serialize it, and have a temporary Aiken project accept it through the real validator path
- round-trip a non-empty signed header through issuance, proof derivation, registry serialization, and on-chain verification
- build and submit a real validator spend on the local `cardano-node-clients` devnet

### Conformance tests

- reproduce an imported deterministic signature fixture
- verify an imported signature fixture
- verify an imported proof fixture
- verify selective-disclosure proof fixtures, including no-header and no-presentation-header cases

## Commands

Run the full repository gate:

```bash
just ci
```

Run just the off-chain tests:

```bash
just test-offchain
```

## Current Gap

Validator coverage is still split between embedded Aiken tests in [bbs_credential.ak](/code/cardano-bbs-verify/onchain/validators/bbs_credential.ak) and generated acceptance coverage from [RoundTripSpec.hs](/code/cardano-bbs-verify/offchain/test/Integration/RoundTripSpec.hs). The current Aiken toolchain does not exercise standalone `onchain/test/` modules in this repo, so active validator tests still live with the validator code for now.

The local submitted-transaction path is now covered by [TxSubmitSpec.hs](/code/cardano-bbs-verify/offchain/test/Integration/TxSubmitSpec.hs). What is still missing is a public Cardano testnet run rather than the local `cardano-node-clients` devnet.
