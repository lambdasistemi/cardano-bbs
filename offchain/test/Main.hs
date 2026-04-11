module Main where

import qualified Conformance.ProofSpec
import qualified Conformance.SignatureSpec
import Test.Hspec
import qualified Unit.CredentialSpec

main :: IO ()
main = hspec $ do
  Unit.CredentialSpec.spec
  Conformance.SignatureSpec.spec
  Conformance.ProofSpec.spec
