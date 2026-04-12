{-# LANGUAGE OverloadedStrings #-}

module Conformance.SelectiveDisclosureSpec (spec) where

import Cardano.BBS.Credential (Attribute (..), Header (..))
import Cardano.BBS.FFI (
  Proof (..),
  PublicKey (..),
 )
import Cardano.BBS.Proof (PresentationHeader (..))
import Cardano.BBS.Verify (verifyProof)
import Data.Aeson ((.:))
import qualified Data.Aeson as Aeson
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base16 as Base16
import qualified Data.ByteString.Lazy as LBS
import Test.Hspec

data SelectiveDisclosureFixture = SelectiveDisclosureFixture
  { fixtureCaseName :: String
  , fixturePublicKey :: PublicKey
  , fixtureHeader :: Maybe Header
  , fixturePresentationHeader :: PresentationHeader
  , fixtureDisclosedIndexes :: [Int]
  , fixtureDisclosedMessages :: [Attribute]
  , fixtureProof :: Proof
  }

instance Aeson.FromJSON SelectiveDisclosureFixture where
  parseJSON = Aeson.withObject "SelectiveDisclosureFixture" $ \o -> do
    caseName <- o .: "caseName"
    pk <- o .: "signerPublicKey"
    header <- o .: "header"
    ph <- o .: "presentationHeader"
    messages <- o .: "messages"
    disclosed <- o .: "disclosedIndexes"
    proof <- o .: "proof"
    pure
      SelectiveDisclosureFixture
        { fixtureCaseName = caseName
        , fixturePublicKey = PublicKey (decodeHexUtf8 pk)
        , fixtureHeader = emptyMeansNothing header
        , fixturePresentationHeader = PresentationHeader (decodeHexUtf8 ph)
        , fixtureDisclosedIndexes = disclosed
        , fixtureDisclosedMessages =
            Attribute . decodeHexUtf8 <$> selectDisclosed messages disclosed
        , fixtureProof = Proof (decodeHexUtf8 proof)
        }

emptyMeansNothing :: String -> Maybe Header
emptyMeansNothing "" = Nothing
emptyMeansNothing hex = Just (Header (decodeHexUtf8 hex))

selectDisclosed :: [String] -> [Int] -> [String]
selectDisclosed messages =
  fmap (messages !!)

decodeHexUtf8 :: String -> BS.ByteString
decodeHexUtf8 input =
  case Base16.decode (BS.pack (fmap (fromIntegral . fromEnum) input)) of
    Right bytes -> bytes
    Left err -> error ("invalid hex fixture: " <> err)

loadFixture :: FilePath -> IO SelectiveDisclosureFixture
loadFixture path = do
  bytes <- LBS.readFile path
  case Aeson.eitherDecode bytes of
    Right fixture -> pure fixture
    Left err -> error err

spec :: Spec
spec =
  describe "Conformance.SelectiveDisclosureSpec" $
    mapM_
      selectiveDisclosureCase
      [ "test/Conformance/fixtures/bls12-381-sha-256/proof/proof003.json"
      , "test/Conformance/fixtures/bls12-381-sha-256/proof/proof014.json"
      , "test/Conformance/fixtures/bls12-381-sha-256/proof/proof015.json"
      ]

selectiveDisclosureCase :: FilePath -> Spec
selectiveDisclosureCase fixturePath =
  it ("verifies " <> fixturePath) $ do
    fixture <- loadFixture fixturePath
    verifyProof
      (fixturePublicKey fixture)
      (fixtureHeader fixture)
      (fixturePresentationHeader fixture)
      (fixtureDisclosedMessages fixture)
      (fixtureDisclosedIndexes fixture)
      (fixtureProof fixture)
      `shouldReturn` True
