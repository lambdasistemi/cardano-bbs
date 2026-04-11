{-# LANGUAGE OverloadedStrings #-}

module Unit.SerializeSpec (spec) where

import Cardano.BBS.Credential (
  Attribute (..),
  Header (..),
  issueCredential,
 )
import Cardano.BBS.KeyGen (PublicKey (..), generateKeyPair)
import Cardano.BBS.Proof (
  PresentationHeader (..),
  deriveProof,
 )
import Cardano.BBS.Serialize (
  BBSProofDatum (..),
  G1Element (..),
  PlutusData (..),
  decodePlutusData,
  proofRedeemerData,
  proofRedeemerToCBOR,
  publicKeyToCBOR,
  regulatorRegistryToCBOR,
 )
import qualified Data.ByteString as BS
import Test.Hspec

spec :: Spec
spec = describe "Unit.SerializeSpec" $ do
  it "serializes a BBS proof redeemer as Aiken-compatible plutus data" $ do
    (sk, pk) <- generateKeyPair
    let header = Just (Header "cardano-bbs-test-header")
        ph = PresentationHeader "txn:serialize"
        attrs = [Attribute "jurisdiction:EU", Attribute "role:issuer", Attribute "status:active"]
        disclosed = [0, 2]
    credential <- issueCredential sk pk header attrs
    proof <- deriveProof pk credential header ph attrs disclosed

    datum <- expectRightSatisfying (proofRedeemerData proof ph attrs disclosed) validProofShape
    encoded <- expectRightSatisfying (proofRedeemerToCBOR proof ph attrs disclosed) (const True)
    _decoded <- expectRightSatisfying (decodePlutusData encoded) matchesDecodedProofShape

    disclosedIndices datum `shouldBe` [0, 2]
    disclosedValues datum `shouldBe` ["jurisdiction:EU", "status:active"]
    nonce datum `shouldBe` "txn:serialize"

  it "serializes regulator registries and bare public keys with distinct shapes" $ do
    (_, pk) <- generateKeyPair

    decodePlutusData (publicKeyToCBOR pk)
      `shouldBe` Right (Constr 0 [Bytes (unPublicKey pk)])

    decodePlutusData (regulatorRegistryToCBOR pk ["jurisdiction", "role"])
      `shouldBe` Right
        ( Constr
            0
            [ Constr 0 [Bytes (unPublicKey pk)]
            , List [Bytes "jurisdiction", Bytes "role"]
            ]
        )

  it "rejects unsorted disclosure sets before encoding" $ do
    (sk, pk) <- generateKeyPair
    let header = Just (Header "cardano-bbs-test-header")
        ph = PresentationHeader "txn:serialize"
        attrs = [Attribute "alpha", Attribute "beta", Attribute "gamma"]
    credential <- issueCredential sk pk header attrs
    proof <- deriveProof pk credential header ph attrs [0, 2]

    proofRedeemerData proof ph attrs [2, 0]
      `shouldBe` Left "disclosure set must be sorted in ascending order"

validProofShape :: BBSProofDatum -> Bool
validProofShape datum =
  all
    (> 0)
    [ BS.length (g1Bytes (aBar datum))
    , BS.length (g1Bytes (bBar datum))
    , BS.length (g1Bytes (d datum))
    , BS.length (eHat datum)
    , BS.length (r1Hat datum)
    , BS.length (r3Hat datum)
    , BS.length (challenge datum)
    ]
    && length (mHat datum) == 1

matchesDecodedProofShape :: PlutusData -> Bool
matchesDecodedProofShape (Constr 0 fields) =
  case fields of
    [ Constr 0 [Bytes aBarBytes]
      , Constr 0 [Bytes bBarBytes]
      , Constr 0 [Bytes dBytes]
      , Bytes eHatBytes
      , Bytes r1HatBytes
      , Bytes r3HatBytes
      , List [Bytes mHatBytes]
      , Bytes cBytes
      , List [Integer 0, Integer 2]
      , List [Bytes "jurisdiction:EU", Bytes "status:active"]
      , Bytes "txn:serialize"
      ] ->
        all
          ((> 0) . BS.length)
          [aBarBytes, bBarBytes, dBytes, eHatBytes, r1HatBytes, r3HatBytes, mHatBytes, cBytes]
    _ -> False
matchesDecodedProofShape _ = False

expectRightSatisfying :: (Show a) => Either String a -> (a -> Bool) -> IO a
expectRightSatisfying value predicate =
  case value of
    Right x -> (x `shouldSatisfy` predicate) >> pure x
    Left err -> expectationFailure err >> fail err
