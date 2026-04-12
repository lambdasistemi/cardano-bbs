{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Integration.RoundTripSpec (spec) where

import Cardano.BBS.Credential (
  Attribute (..),
  issueCredential,
 )
import Cardano.BBS.KeyGen (generateKeyPair)
import Cardano.BBS.Proof (
  PresentationHeader (..),
  deriveProof,
 )
import Cardano.BBS.Serialize (
  BBSProofDatum (..),
  G1Element (..),
  G2Element (..),
  RegulatorRegistryDatum (..),
  decodePlutusData,
  proofRedeemerData,
  proofRedeemerToCBOR,
  regulatorRegistryData,
  regulatorRegistryToCBOR,
 )
import Cardano.BBS.Verify (verifyProof)
import Control.Exception (bracket)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.List (intercalate)
import Numeric (showHex)
import System.Directory (
  copyFile,
  createDirectory,
  doesDirectoryExist,
  getTemporaryDirectory,
  listDirectory,
  makeAbsolute,
  removeFile,
  removePathForcibly,
 )
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import System.IO (hClose, openTempFile)
import System.Process (
  CreateProcess (cwd),
  proc,
  readCreateProcessWithExitCode,
 )
import Test.Hspec

spec :: Spec
spec =
  describe "Integration.RoundTripSpec" $
    it "accepts an off-chain generated proof in the on-chain validator" $ do
      (sk, pk) <- generateKeyPair
      let attrs =
            [ Attribute "jurisdiction:EU"
            , Attribute "role:issuer"
            , Attribute "status:active"
            ]
          disclosed = [0, 2]
          disclosedAttrs = [Attribute "jurisdiction:EU", Attribute "status:active"]
          txId =
            BS.pack
              [ 0x10
              , 0x11
              , 0x12
              , 0x13
              , 0x14
              , 0x15
              , 0x16
              , 0x17
              , 0x18
              , 0x19
              , 0x1A
              , 0x1B
              , 0x1C
              , 0x1D
              , 0x1E
              , 0x1F
              , 0x20
              , 0x21
              , 0x22
              , 0x23
              , 0x24
              , 0x25
              , 0x26
              , 0x27
              , 0x28
              , 0x29
              , 0x2A
              , 0x2B
              , 0x2C
              , 0x2D
              , 0x2E
              , 0x2F
              ]
          ph = PresentationHeader txId

      credential <- issueCredential sk pk Nothing attrs
      proof <- deriveProof pk credential Nothing ph attrs disclosed
      verifyProof pk Nothing ph disclosedAttrs disclosed proof `shouldReturn` True

      proofDatum <- expectRight "proofRedeemerData" $ proofRedeemerData proof ph attrs disclosed
      let registryDatum = regulatorRegistryData pk (attributeBytes <$> attrs)

      proofCbor <- expectRight "proofRedeemerToCBOR" $ proofRedeemerToCBOR proof ph attrs disclosed
      let registryCbor = regulatorRegistryToCBOR pk (attributeBytes <$> attrs)
      decodePlutusData proofCbor `shouldSatisfy` isRight
      decodePlutusData registryCbor `shouldSatisfy` isRight

      withTempOnchainProject $ \onchainDir -> do
        appendFileUtf8
          (onchainDir </> "validators" </> "bbs_credential.ak")
          (renderRoundTripTest registryDatum proofDatum txId)
        (exitCode, stdoutText, stderrText) <-
          readCreateProcessWithExitCode ((proc "aiken" ["check"]){cwd = Just onchainDir}) ""
        case exitCode of
          ExitSuccess -> pure ()
          ExitFailure _ ->
            expectationFailure $
              unlines
                [ "aiken check failed for round-trip fixture"
                , stdoutText
                , stderrText
                ]

expectRight :: (HasCallStack) => String -> Either String a -> IO a
expectRight label = \case
  Right value -> pure value
  Left err -> expectationFailure (label <> ": " <> err) >> error "unreachable"

isRight :: Either a b -> Bool
isRight = \case
  Right _ -> True
  Left _ -> False

attributeBytes :: Attribute -> ByteString
attributeBytes (Attribute bytes) = bytes

withTempOnchainProject :: (FilePath -> IO a) -> IO a
withTempOnchainProject = bracket createTempProject removePathForcibly
  where
    createTempProject = do
      root <- uniqueTempDirectory "cardano-bbs-roundtrip"
      sourceRoot <- makeAbsolute "../onchain"
      copyFile (sourceRoot </> "aiken.toml") (root </> "aiken.toml")
      copyFile (sourceRoot </> "aiken.lock") (root </> "aiken.lock")
      copyDirectoryRecursive (sourceRoot </> "lib") (root </> "lib")
      copyDirectoryRecursive (sourceRoot </> "validators") (root </> "validators")
      pure root

uniqueTempDirectory :: String -> IO FilePath
uniqueTempDirectory prefix = do
  tempRoot <- getTemporaryDirectory
  (path, handle) <- openTempFile tempRoot prefix
  hClose handle
  removeFile path
  createDirectory path
  pure path

copyDirectoryRecursive :: FilePath -> FilePath -> IO ()
copyDirectoryRecursive source destination = do
  createDirectory destination
  entries <- listDirectory source
  mapM_ copyEntry entries
  where
    copyEntry entry = do
      let sourcePath = source </> entry
          destinationPath = destination </> entry
      isDirectory <- doesDirectoryExist sourcePath
      if isDirectory
        then copyDirectoryRecursive sourcePath destinationPath
        else copyFile sourcePath destinationPath

appendFileUtf8 :: FilePath -> String -> IO ()
appendFileUtf8 = appendFile

renderRoundTripTest ::
  RegulatorRegistryDatum ->
  BBSProofDatum ->
  ByteString ->
  String
renderRoundTripTest registry proof txId =
  unlines
    [ ""
    , "test spend_accepts_offchain_roundtrip_proof() {"
    , "  let registry = " <> renderRegistry registry
    , "  let self = Transaction { ..placeholder, id: " <> renderBytes txId <> " }"
    , "  let proof = " <> renderProof proof
    , ""
    , "  bbs_credential.spend(Some(registry), proof, sample_output_reference(), self)"
    , "}"
    ]

renderRegistry :: RegulatorRegistryDatum -> String
renderRegistry registry =
  unlines
    [ "RegulatorRegistry {"
    , "    regulator_pk: " <> renderG2 (regulatorPk registry) <> ","
    , "    credential_schema: " <> renderBytesList (credentialSchema registry)
    , "  }"
    ]

renderProof :: BBSProofDatum -> String
renderProof proof =
  unlines
    [ "BBSProof {"
    , "    a_bar: " <> renderG1 (aBar proof) <> ","
    , "    b_bar: " <> renderG1 (bBar proof) <> ","
    , "    d: " <> renderG1 (d proof) <> ","
    , "    e_hat: " <> renderBytes (eHat proof) <> ","
    , "    r1_hat: " <> renderBytes (r1Hat proof) <> ","
    , "    r3_hat: " <> renderBytes (r3Hat proof) <> ","
    , "    m_hat: " <> renderBytesList (mHat proof) <> ","
    , "    c: " <> renderBytes (challenge proof) <> ","
    , "    disclosed_indices: " <> renderIntList (disclosedIndices proof) <> ","
    , "    disclosed_values: " <> renderBytesList (disclosedValues proof) <> ","
    , "    nonce: " <> renderBytes (nonce proof)
    , "  }"
    ]

renderG1 :: G1Element -> String
renderG1 (G1Element bytes) =
  "G1Element { bytes: " <> renderBytes bytes <> " }"

renderG2 :: G2Element -> String
renderG2 (G2Element bytes) =
  "G2Element { bytes: " <> renderBytes bytes <> " }"

renderBytesList :: [ByteString] -> String
renderBytesList values =
  "[" <> intercalate ", " (renderBytes <$> values) <> "]"

renderIntList :: [Int] -> String
renderIntList values =
  "[" <> intercalate ", " (show <$> values) <> "]"

renderBytes :: ByteString -> String
renderBytes bytes =
  "#\"" <> concatMap renderByte (BS.unpack bytes) <> "\""
  where
    renderByte byte =
      let rendered = showHex byte ""
       in if length rendered == 1 then '0' : rendered else rendered
