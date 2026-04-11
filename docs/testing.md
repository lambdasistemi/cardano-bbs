# Testing

## Current Test Coverage

The current off-chain coverage focuses on correctness against imported fixtures and minimal API round-trips.

### Unit tests

- issue a credential and verify it
- reject a tampered attribute set
- derive a selective disclosure proof and verify it

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

There are no Aiken tests yet for the validators, because the validator logic is still scaffold-level.
