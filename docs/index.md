# cardano-bbs

`cardano-bbs` is a split Cardano project:

- `offchain/` contains the Haskell API and the Rust FFI bridge to [`zkryptium`](https://crates.io/crates/zkryptium).
- `onchain/` contains the Aiken validator scaffold for future BBS+ and BLS verification.

## Current Status

The repository is not feature-complete. What is implemented today is the off-chain foundation for the BBS+ issuance and proof flow:

- BBS+ key generation through Rust FFI
- BBS+ signature issuance through Rust FFI
- BBS+ signature verification through Rust FFI
- BBS+ proof generation through Rust FFI
- BBS+ proof verification through Rust FFI
- Haskell tests that validate against imported IETF fixtures

The on-chain verifier is still scaffold-level. The Aiken modules compile and produce a blueprint, but they do not yet implement the BBS+ pairing equations from the spec.

## What The Repo Gives You Today

The Haskell API already supports:

```haskell
generateKeyPair :: IO (SecretKey, PublicKey)
issueCredential :: SecretKey -> PublicKey -> Maybe Header -> [Attribute] -> IO Credential
verifyCredential :: PublicKey -> Maybe Header -> [Attribute] -> Credential -> IO Bool
deriveProof :: PublicKey -> Credential -> Maybe Header -> PresentationHeader -> [Attribute] -> DisclosureSet -> IO Proof
verifyProof :: PublicKey -> Maybe Header -> PresentationHeader -> [Attribute] -> DisclosureSet -> Proof -> IO Bool
```

## What Is Still Missing

- A real on-chain BBS+ verifier in Aiken
- Round-trip serialization that matches the future validator ABI
- Budget measurements and Aiken tests for verification cost
- BLS aggregate signature support
- Revocation
- End-user documentation for selective disclosure and integration patterns

## Repository Layout

```text
cardano-bbs/
├── offchain/
│   ├── cbits/zkryptium-ffi/    # Rust cdylib exposed to Haskell
│   ├── src/Cardano/BBS/        # Haskell BBS modules
│   └── test/                   # Unit and conformance tests
├── onchain/
│   ├── lib/
│   └── validators/
└── specs/001-bbs-credentials/  # feature spec, plan, research, tasks
```
