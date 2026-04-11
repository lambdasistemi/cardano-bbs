# Off-Chain API Contract (Haskell Library)

## Key Generation

```haskell
generateKeyPair :: IO (SecretKey, PublicKey)
```

## Credential Issuance

```haskell
issueCredential :: SecretKey -> [Attribute] -> IO Credential
```

## Proof Derivation

```haskell
deriveProof
  :: Credential
  -> DisclosureSet    -- which attribute indices to reveal
  -> Nonce            -- transaction-binding context
  -> IO Proof
```

## Off-Chain Verification

```haskell
verifyProof
  :: PublicKey
  -> Proof
  -> Nonce
  -> Bool
```

## BLS Signing and Aggregation

```haskell
blsSign :: BLSSecretKey -> ByteString -> IO BLSSignature

blsAggregate :: [BLSSignature] -> AggregateSignature

blsVerifyAggregate
  :: AggregateSignature
  -> ByteString        -- message
  -> [BLSPublicKey]    -- participating signers
  -> Bool
```

## Serialization

```haskell
proofToCBOR :: Proof -> ByteString           -- for use as Plutus redeemer
publicKeyToCBOR :: PublicKey -> ByteString    -- for on-chain datum
aggregateSigToCBOR :: AggregateSignature -> ByteString
```
