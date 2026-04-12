# Testing

## Current Test Coverage

The current coverage now spans imported cryptographic fixtures, off-chain API checks, and a real off-chain to on-chain round-trip.

### Unit tests

- issue a credential and verify it
- reject a tampered attribute set
- derive a selective disclosure proof and verify it
- generate a proof off-chain, serialize it, and have a temporary Aiken project accept it through the real validator path

### Conformance tests

- reproduce an imported deterministic signature fixture
- verify an imported signature fixture
- verify an imported proof fixture

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

Validator coverage is still mostly embedded inside [verify.ak](/code/cardano-bbs-verify/onchain/lib/bbs/verify.ak) and [bbs_credential.ak](/code/cardano-bbs-verify/onchain/validators/bbs_credential.ak). The next cleanup step is to move that coverage into dedicated `onchain/test/` modules.
