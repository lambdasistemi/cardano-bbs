# Off-Chain API

## Haskell Surface

The public off-chain modules are:

- `Cardano.BBS.KeyGen`
- `Cardano.BBS.Credential`
- `Cardano.BBS.Proof`
- `Cardano.BBS.Verify`
- `Cardano.BBS.Serialize`

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

That design is intentional for the current phase. It keeps the cryptographic boundary narrow while higher-level integration types are derived explicitly at the serialization layer.

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

`deriveProof` already supports selective disclosure directly through `DisclosureSet`, where each integer is an attribute index to reveal.

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

### On-Chain Serialization

```haskell
proofRedeemerData
  :: Proof
  -> PresentationHeader
  -> [Attribute]
  -> DisclosureSet
  -> Either String BBSProofDatum

proofRedeemerToCBOR
  :: Proof
  -> PresentationHeader
  -> [Attribute]
  -> DisclosureSet
  -> Either String ByteString

publicKeyToCBOR :: PublicKey -> ByteString

regulatorRegistryToCBOR
  :: PublicKey
  -> [ByteString]
  -> ByteString
```

`proofRedeemerToCBOR` parses the opaque `zkryptium` proof bytes into the field layout expected by the Aiken `BBSProof` redeemer:

- three compressed G1 points: `a_bar`, `b_bar`, `d`
- scalar responses: `e_hat`, `r1_hat`, `r3_hat`, `c`
- one `m_hat` scalar per undisclosed attribute
- disclosed indices and disclosed values
- the presentation header reused as the on-chain nonce

The module also exposes a minimal Plutus `Data` encoder/decoder so the off-chain contract can be tested without needing the full Plutus ledger API in this package.

## Caveats

- `verifyCredential` and `verifyProof` currently return `False` on cryptographic failure rather than surfacing a rich error type.
- The serializer currently targets the `BBSProof` and `RegulatorRegistry` data shapes only. The validator logic that consumes them is still stub-level.
- `proofRedeemerToCBOR` requires the original attribute list and disclosure set because the raw proof bytes alone do not contain disclosed values or message-count context.
- The API is usable for off-chain testing and redeemer construction today, but it is not yet the final end-to-end integration API.
