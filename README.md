# cardano-bbs

BBS+ anonymous credentials for Cardano — Haskell off-chain library + Aiken on-chain verifier.

## Status

Early development.

## Structure

- `offchain/` — Haskell library: BBS+ credential issuance, proof derivation, serialization
- `onchain/` — Aiken validators: BBS+ proof-of-knowledge verification using CIP-0381 BLS12-381 built-ins

## Development

```bash
nix develop
```
