# Off-Chain API

## Haskell Surface

The public off-chain modules are:

- `Cardano.BBS.KeyGen`
- `Cardano.BBS.Credential`
- `Cardano.BBS.Proof`
- `Cardano.BBS.Verify`

## Data Model

The current Haskell wrappers are raw-byte carriers over the serialized `zkryptium` outputs:

```haskell
newtype SecretKey = SecretKey ByteString
newtype PublicKey = PublicKey ByteString
newtype Credential = Credential ByteString
newtype Proof = Proof ByteString
newtype Header = Header ByteString
newtype PresentationHeader = PresentationHeader ByteString
newtype Attribute = Attribute ByteString
type DisclosureSet = [Int]
```

That design is intentional for the current phase. It keeps the public API small while the serialization contract is still evolving.

## Implemented Functions

### Key Generation

```haskell
generateKeyPair :: IO (SecretKey, PublicKey)
```

### Credential Issuance

```haskell
issueCredential
  :: SecretKey
  -> PublicKey
  -> Maybe Header
  -> [Attribute]
  -> IO Credential
```

### Signature Verification

```haskell
verifyCredential
  :: PublicKey
  -> Maybe Header
  -> [Attribute]
  -> Credential
  -> IO Bool
```

### Proof Derivation

```haskell
deriveProof
  :: PublicKey
  -> Credential
  -> Maybe Header
  -> PresentationHeader
  -> [Attribute]
  -> DisclosureSet
  -> IO Proof
```

### Proof Verification

```haskell
verifyProof
  :: PublicKey
  -> Maybe Header
  -> PresentationHeader
  -> [Attribute]
  -> DisclosureSet
  -> Proof
  -> IO Bool
```

## Caveats

- `verifyCredential` and `verifyProof` currently return `False` on cryptographic failure rather than surfacing a rich error type.
- The on-chain serialization contract is not finalized yet, so `Credential` and `Proof` are not yet exposed as CBOR records tailored to Aiken.
- The API is usable for off-chain testing today, but it is not yet the final integration API.
