module Main where

import qualified Conformance.ProofSpec
import qualified Conformance.SignatureSpec
import qualified Integration.RoundTripSpec
import Test.Hspec
import qualified Unit.CredentialSpec
import qualified Unit.SerializeSpec

main :: IO ()
main = hspec $ do
  Integration.RoundTripSpec.spec
  Unit.CredentialSpec.spec
  Unit.SerializeSpec.spec
  Conformance.SignatureSpec.spec
  Conformance.ProofSpec.spec
