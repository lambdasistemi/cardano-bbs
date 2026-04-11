{-# LANGUAGE OverloadedStrings #-}

module Conformance.SignatureSpec (spec) where

import Cardano.BBS.Credential (
  Attribute (..),
  Credential (..),
  Header (..),
  issueCredential,
 )
import Cardano.BBS.FFI (
  PublicKey (..),
  SecretKey (..),
 )
import Cardano.BBS.Verify (verifyCredential)
import Data.Aeson ((.:))
import qualified Data.Aeson as Aeson
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base16 as Base16
import qualified Data.ByteString.Lazy as LBS
import Test.Hspec

data SignatureFixture = SignatureFixture
  { fixtureSecretKey :: SecretKey
  , fixturePublicKey :: PublicKey
  , fixtureHeader :: Header
  , fixtureMessages :: [Attribute]
  , fixtureSignature :: Credential
  }

instance Aeson.FromJSON SignatureFixture where
  parseJSON = Aeson.withObject "SignatureFixture" $ \o -> do
    signer <- o .: "signerKeyPair"
    header <- o .: "header"
    messages <- o .: "messages"
    signature <- o .: "signature"
    secretKeyHex <- Aeson.withObject "signer" (.: "secretKey") signer
    publicKeyHex <- Aeson.withObject "signer" (.: "publicKey") signer
    pure
      SignatureFixture
        { fixtureSecretKey = SecretKey (decodeHexUtf8 secretKeyHex)
        , fixturePublicKey = PublicKey (decodeHexUtf8 publicKeyHex)
        , fixtureHeader = Header (decodeHexUtf8 header)
        , fixtureMessages = fmap (Attribute . decodeHexUtf8) messages
        , fixtureSignature = Credential (decodeHexUtf8 signature)
        }

decodeHexUtf8 :: String -> BS.ByteString
decodeHexUtf8 input =
  case Base16.decode (BS.pack (fmap (fromIntegral . fromEnum) input)) of
    Right bytes -> bytes
    Left err -> error ("invalid hex fixture: " <> err)

loadFixture :: IO SignatureFixture
loadFixture = do
  bytes <- LBS.readFile "test/Conformance/fixtures/bls12-381-sha-256/signature/signature001.json"
  case Aeson.eitherDecode bytes of
    Right fixture -> pure fixture
    Left err -> error err

spec :: Spec
spec = describe "Conformance.SignatureSpec" $ do
  it "reproduces the deterministic IETF single-message signature fixture" $ do
    fixture <- loadFixture
    signature <-
      issueCredential
        (fixtureSecretKey fixture)
        (fixturePublicKey fixture)
        (Just (fixtureHeader fixture))
        (fixtureMessages fixture)
    signature `shouldBe` fixtureSignature fixture

  it "verifies the imported IETF single-message signature fixture" $ do
    fixture <- loadFixture
    verifyCredential
      (fixturePublicKey fixture)
      (Just (fixtureHeader fixture))
      (fixtureMessages fixture)
      (fixtureSignature fixture)
      `shouldReturn` True
