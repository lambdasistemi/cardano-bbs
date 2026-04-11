{-# LANGUAGE OverloadedStrings #-}

module Conformance.ProofSpec (spec) where

import Cardano.BBS.Credential (Attribute (..), Header (..))
import Cardano.BBS.FFI (
  Proof (..),
  PublicKey (..),
 )
import Cardano.BBS.Proof (
  PresentationHeader (..),
 )
import Cardano.BBS.Verify (verifyProof)
import Data.Aeson ((.:))
import qualified Data.Aeson as Aeson
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base16 as Base16
import qualified Data.ByteString.Lazy as LBS
import Test.Hspec

data ProofFixture = ProofFixture
  { fixturePublicKey :: PublicKey
  , fixtureHeader :: Header
  , fixturePresentationHeader :: PresentationHeader
  , fixtureDisclosedIndexes :: [Int]
  , fixtureDisclosedMessages :: [Attribute]
  , fixtureProof :: Proof
  }

instance Aeson.FromJSON ProofFixture where
  parseJSON = Aeson.withObject "ProofFixture" $ \o -> do
    pk <- o .: "signerPublicKey"
    header <- o .: "header"
    ph <- o .: "presentationHeader"
    msgs <- o .: "messages"
    disclosed <- o .: "disclosedIndexes"
    proof <- o .: "proof"
    pure
      ProofFixture
        { fixturePublicKey = PublicKey (decodeHexUtf8 pk)
        , fixtureHeader = Header (decodeHexUtf8 header)
        , fixturePresentationHeader = PresentationHeader (decodeHexUtf8 ph)
        , fixtureDisclosedIndexes = disclosed
        , fixtureDisclosedMessages = fmap (Attribute . decodeHexUtf8) msgs
        , fixtureProof = Proof (decodeHexUtf8 proof)
        }

decodeHexUtf8 :: String -> BS.ByteString
decodeHexUtf8 input =
  case Base16.decode (BS.pack (fmap (fromIntegral . fromEnum) input)) of
    Right bytes -> bytes
    Left err -> error ("invalid hex fixture: " <> err)

loadFixture :: IO ProofFixture
loadFixture = do
  bytes <- LBS.readFile "test/Conformance/fixtures/bls12-381-sha-256/proof/proof001.json"
  case Aeson.eitherDecode bytes of
    Right fixture -> pure fixture
    Left err -> error err

spec :: Spec
spec = describe "Conformance.ProofSpec" $
  it "verifies the imported IETF proof fixture" $ do
    fixture <- loadFixture
    verifyProof
      (fixturePublicKey fixture)
      (Just (fixtureHeader fixture))
      (fixturePresentationHeader fixture)
      (fixtureDisclosedMessages fixture)
      (fixtureDisclosedIndexes fixture)
      (fixtureProof fixture)
      `shouldReturn` True
