# Testing

## Current Test Coverage

The current coverage spans imported cryptographic fixtures, off-chain API checks, and a real off-chain to on-chain round-trip.

### Unit tests

- issue a credential and verify it
- reject a tampered attribute set
- derive a selective disclosure proof and verify it
- generate a proof off-chain, serialize it, and have a temporary Aiken project accept it through the real validator path
- round-trip a non-empty signed header through issuance, proof derivation, registry serialization, and on-chain verification

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

Validator coverage is still mostly embedded inside [verify.ak](/code/cardano-bbs-verify/onchain/lib/bbs/verify.ak) and [bbs_credential.ak](/code/cardano-bbs-verify/onchain/validators/bbs_credential.ak). The current Aiken toolchain does not exercise standalone `onchain/test/` modules in this repo, so active validator tests live with the validator code for now.

There is still no submitted-transaction integration test through `cardano-node-clients`; the current round-trip stops at local validator execution.
