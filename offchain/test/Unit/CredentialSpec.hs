{-# LANGUAGE OverloadedStrings #-}

module Unit.CredentialSpec (spec) where

import Cardano.BBS.Credential (
  Attribute (..),
  Header (..),
  issueCredential,
 )
import Cardano.BBS.KeyGen (generateKeyPair)
import Cardano.BBS.Proof (
  PresentationHeader (..),
  deriveProof,
 )
import Cardano.BBS.Verify (
  verifyCredential,
  verifyProof,
 )
import Test.Hspec

spec :: Spec
spec = describe "Unit.CredentialSpec" $ do
  it "issues and verifies a credential" $ do
    (sk, pk) <- generateKeyPair
    let header = Just (Header "cardano-bbs-test-header")
        attrs = [Attribute "alpha", Attribute "beta", Attribute "gamma"]
    credential <- issueCredential sk pk header attrs
    verifyCredential pk header attrs credential `shouldReturn` True
    verifyCredential pk header [Attribute "tampered", Attribute "beta", Attribute "gamma"] credential
      `shouldReturn` False

  it "derives and verifies a selective disclosure proof" $ do
    (sk, pk) <- generateKeyPair
    let header = Just (Header "cardano-bbs-test-header")
        ph = PresentationHeader "txn:roundtrip"
        attrs = [Attribute "jurisdiction:EU", Attribute "role:issuer", Attribute "status:active"]
        disclosed = [0, 2]
        disclosedAttrs = [Attribute "jurisdiction:EU", Attribute "status:active"]
    credential <- issueCredential sk pk header attrs
    proof <- deriveProof pk credential header ph attrs disclosed
    verifyProof pk header ph disclosedAttrs disclosed proof `shouldReturn` True
