module Main where

import qualified Conformance.ProofSpec
import qualified Conformance.SelectiveDisclosureSpec
import qualified Conformance.SignatureSpec
import qualified Integration.RoundTripSpec
import Test.Hspec
import qualified Unit.CredentialSpec
import qualified Unit.SerializeSpec
import qualified Unit.TxBuildSpec

main :: IO ()
main = hspec $ do
  Integration.RoundTripSpec.spec
  Unit.CredentialSpec.spec
  Unit.SerializeSpec.spec
  Unit.TxBuildSpec.spec
  Conformance.SignatureSpec.spec
  Conformance.ProofSpec.spec
  Conformance.SelectiveDisclosureSpec.spec
