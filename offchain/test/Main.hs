module Main where

import qualified Conformance.ProofSpec
import qualified Conformance.SignatureSpec
import Test.Hspec
import qualified Unit.CredentialSpec
import qualified Unit.SerializeSpec

main :: IO ()
main = hspec $ do
  Unit.CredentialSpec.spec
  Unit.SerializeSpec.spec
  Conformance.SignatureSpec.spec
  Conformance.ProofSpec.spec
