{-# LANGUAGE DataKinds #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Integration.TxSubmitSpec (spec) where

import Cardano.BBS.Credential (
  Attribute (..),
  Header (..),
  issueCredential,
 )
import qualified Cardano.BBS.FFI as FFI
import Cardano.BBS.KeyGen (generateKeyPair)
import Cardano.BBS.Proof (
  PresentationHeader (..),
  deriveProof,
 )
import Cardano.BBS.TxBuild (
  RawPlutusData,
  proofRedeemerRawPlutusData,
  regulatorRegistryRawPlutusData,
 )
import Cardano.Crypto.Hash (hashToBytes)
import Cardano.Ledger.Address (Addr (..))
import Cardano.Ledger.Alonzo.Scripts (
  fromPlutusScript,
  mkPlutusScript,
 )
import Cardano.Ledger.Api.Scripts.Data (Datum (NoDatum))
import Cardano.Ledger.Api.Tx (Tx)
import Cardano.Ledger.Api.Tx.In (TxId (..))
import Cardano.Ledger.Api.Tx.Out (
  TxOut,
  coinTxOutL,
  datumTxOutL,
 )
import Cardano.Ledger.BaseTypes (
  Inject (inject),
  Network (Testnet),
  TxIx (TxIx),
 )
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Core (
  PParams,
  Script,
  extractHash,
  hashScript,
 )
import Cardano.Ledger.Credential (
  Credential (ScriptHashObj),
  StakeReference (StakeRefNull),
 )
import Cardano.Ledger.Plutus.Language (
  Language (PlutusV3),
  Plutus (..),
  PlutusBinary (..),
 )
import Cardano.Ledger.TxIn (TxIn (..))
import Cardano.Node.Client.E2E.Setup (
  addKeyWitness,
  enterpriseAddr,
  genesisAddr,
  genesisSignKey,
  keyHashFromSignKey,
  mkSignKey,
  withDevnet,
 )
import Cardano.Node.Client.N2C.Provider (mkN2CProvider)
import Cardano.Node.Client.N2C.Submitter (mkN2CSubmitter)
import Cardano.Node.Client.Provider (Provider (..))
import Cardano.Node.Client.Submitter (
  SubmitResult (..),
  Submitter (..),
 )
import Cardano.Node.Client.TxBuild (
  InterpretIO (..),
  TxBuild,
  attachScript,
  build,
  collateral,
  payTo,
  payTo',
  spend,
  spendScript,
 )
import Control.Concurrent (threadDelay)
import Control.Exception (SomeException, bracket_, catch)
import Crypto.Hash (Blake2b_256, Digest, hash)
import Data.Aeson (
  FromJSON (..),
  eitherDecodeFileStrict',
  withObject,
  (.:),
  (.:?),
 )
import Data.ByteArray (convert)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Short as SBS
import Data.Char (isDigit)
import Data.IORef (atomicModifyIORef', newIORef)
import Data.List (find)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.Word (Word16, Word8)
import Lens.Micro ((^.))
import System.Directory (
  copyFile,
  createDirectoryIfMissing,
  doesDirectoryExist,
  getTemporaryDirectory,
  listDirectory,
  removePathForcibly,
 )
import System.Environment (lookupEnv, setEnv, unsetEnv)
import System.FilePath ((</>))
import System.Timeout (timeout)
import Test.Hspec
import Prelude

spec :: Spec
spec =
  around withEnv $
    describe "Integration.TxSubmitSpec" $
      it
        "submits a BBS validator spend on devnet through cardano-node-clients"
        submitBbsSpend

type Env =
  ( Provider IO
  , Submitter IO
  , PParams ConwayEra
  , [(TxIn, TxOut ConwayEra)]
  )

withEnv :: (Env -> IO ()) -> IO ()
withEnv action =
  withGenesisEnv $
    withDevnet $ \lsq ltxs -> do
      let provider = mkN2CProvider lsq
          submitter = mkN2CSubmitter ltxs
      pp <- queryProtocolParams provider
      utxos <- queryUTxOs provider genesisAddr
      action (provider, submitter, pp, utxos)

withGenesisEnv :: IO a -> IO a
withGenesisEnv io = do
  previous <- lookupEnv "E2E_GENESIS_DIR"
  target <- prepareGenesisFixture
  let cleanupTarget =
        removePathForcibly target
          `catch` ignoreException
      restore =
        case previous of
          Just value -> setEnv "E2E_GENESIS_DIR" value
          Nothing -> unsetEnv "E2E_GENESIS_DIR"
  bracket_
    (setEnv "E2E_GENESIS_DIR" target)
    (cleanupTarget >> restore)
    io

prepareGenesisFixture :: IO FilePath
prepareGenesisFixture = do
  tempRoot <- getTemporaryDirectory
  let source = "/code/cardano-node-clients/e2e-test/genesis"
      target = tempRoot </> "cardano-bbs-e2e-genesis"
  removePathForcibly target
    `catch` ignoreException
  copyDirectoryRecursive source target
  patchShelleyProtocolMajor (target </> "shelley-genesis.json")
  pure target

copyDirectoryRecursive :: FilePath -> FilePath -> IO ()
copyDirectoryRecursive source target = do
  createDirectoryIfMissing True target
  entries <- listDirectory source
  mapM_ copyEntry entries
  where
    copyEntry entry = do
      let from = source </> entry
          to = target </> entry
      isDir <- doesDirectoryExist from
      if isDir
        then copyDirectoryRecursive from to
        else copyFile from to

patchShelleyProtocolMajor :: FilePath -> IO ()
patchShelleyProtocolMajor path = do
  text <- TE.decodeUtf8 <$> BS.readFile path
  BS.writeFile path (TE.encodeUtf8 (T.replace "\"major\": 9" "\"major\": 10" text))

ignoreException :: SomeException -> IO ()
ignoreException _ = pure ()

submitBbsSpend :: Env -> IO ()
submitBbsSpend (provider, submitter, pp, utxos) = do
  seed@(seedIn, _) <- case utxos of
    u : _ -> pure u
    [] -> fail "no genesis UTxOs"

  validator <- withinSec 10 "load validator" $ loadBbsValidator "../onchain/plutus.json"
  (sk, pk) <- withinSec 10 "generate key pair" generateKeyPair
  let recipient =
        enterpriseAddr $
          keyHashFromSignKey $
            mkSignKey (BS.pack (replicate 32 0x33))
      scriptAddr = validatorAddr validator
      header = Just (Header "cardano-bbs-devnet")
      attrs =
        [ Attribute "jurisdiction:EU"
        , Attribute "role:issuer"
        , Attribute "status:active"
        ]
      disclosed = [0, 2]
      paymentCoin = Coin 10_000_000
      collateralCoin = Coin 5_000_000
      scriptCoin = Coin 7_000_000
      spendCoin = Coin 2_000_000
      registry =
        regulatorRegistryRawPlutusData
          pk
          header
          ["jurisdiction", "role", "status"]
      mockEval _ = pure Map.empty

  credential <- withinSec 10 "issue credential" $ issueCredential sk pk header attrs

  fundingTx <-
    withinSec 30 "build funding tx" $
      expectRightShow "funding build"
        =<< build
          pp
          noCtxInterpretIO
          mockEval
          [seed]
          genesisAddr
          (fundingProgram seedIn scriptAddr scriptCoin paymentCoin collateralCoin registry)
  withinSec 30 "submit funding tx" $
    submitTx submitter (addKeyWitness genesisSignKey fundingTx) >>= \case
      Submitted _ -> pure ()
      Rejected reason ->
        expectationFailure ("funding submitTx rejected: " <> show reason)

  scriptUtxo <-
    withinSec 40 "wait for script utxo" $
      waitForMatchingUtxo provider scriptAddr 30 ((/= NoDatum) . (^. datumTxOutL))
  paymentUtxo <-
    withinSec 40 "wait for payment utxo" $
      waitForMatchingUtxo provider genesisAddr 30 (hasCoin paymentCoin)
  collateralUtxo <-
    withinSec 40 "wait for collateral utxo" $
      waitForMatchingUtxo provider genesisAddr 30 (hasCoin collateralCoin)

  spendTx <-
    withinSec 40 "build spend tx" $
      buildSpend
        provider
        pp
        validator
        pk
        credential
        header
        attrs
        disclosed
        recipient
        spendCoin
        paymentUtxo
        collateralUtxo
        scriptUtxo

  let signed = addKeyWitness genesisSignKey spendTx
  withinSec 30 "submit spend tx" $
    submitTx submitter signed >>= \case
      Submitted _ -> pure ()
      Rejected reason ->
        expectationFailure ("submitTx rejected: " <> show reason)

  recipientUtxo <-
    withinSec 40 "wait for recipient utxo" $
      waitForMatchingUtxo provider recipient 30 (hasCoin spendCoin)
  snd recipientUtxo ^. coinTxOutL `shouldBe` spendCoin

withinSec :: Int -> String -> IO a -> IO a
withinSec sec label io = do
  result <- timeout (sec * 1_000_000) io
  case result of
    Just value -> pure value
    Nothing -> expectationFailure ("timed out in " <> label) >> fail label

fundingProgram ::
  TxIn ->
  Addr ->
  Coin ->
  Coin ->
  Coin ->
  RawPlutusData ->
  TxBuild NoCtx Void ()
fundingProgram seedIn scriptAddr scriptCoin paymentCoin collateralCoin registry = do
  _ <- spend seedIn
  _ <- payTo' scriptAddr (inject scriptCoin) registry
  _ <- payTo genesisAddr (inject paymentCoin)
  _ <- payTo genesisAddr (inject collateralCoin)
  pure ()

buildSpend ::
  Provider IO ->
  PParams ConwayEra ->
  Script ConwayEra ->
  FFI.PublicKey ->
  FFI.Credential ->
  Maybe Header ->
  [Attribute] ->
  [Int] ->
  Addr ->
  Coin ->
  (TxIn, TxOut ConwayEra) ->
  (TxIn, TxOut ConwayEra) ->
  (TxIn, TxOut ConwayEra) ->
  IO (Tx ConwayEra)
buildSpend provider pp validator pk credential header attrs disclosed recipient spendCoin paymentUtxo collateralUtxo scriptUtxo = do
  let ph = PresentationHeader (nonceFromTxIn (fst scriptUtxo))
  proof <- deriveProof pk credential header ph attrs disclosed
  redeemer <-
    expectRight "proofRedeemerRawPlutusData" $
      proofRedeemerRawPlutusData proof ph attrs disclosed
  evalFailures <- newIORef (0 :: Int)
  let eval tx = do
        result <- fmap (Map.map (either (Left . show) Right)) (evaluateTx provider tx)
        case [err | (_, Left err) <- Map.toList result] of
          [] -> pure result
          errs -> do
            attempt <- atomicModifyIORef' evalFailures (\n -> let n' = n + 1 in (n', n'))
            if attempt >= 5
              then
                expectationFailure ("buildSpend repeated eval failure: " <> show errs)
                  >> fail "buildSpend eval failure"
              else pure result
  expectRightShow "script spend build"
    =<< build
      pp
      noCtxInterpretIO
      eval
      [paymentUtxo, collateralUtxo, scriptUtxo]
      genesisAddr
      ( spendProgram
          validator
          (fst paymentUtxo)
          (fst collateralUtxo)
          (fst scriptUtxo)
          redeemer
          recipient
          spendCoin
      )

spendProgram ::
  Script ConwayEra ->
  TxIn ->
  TxIn ->
  TxIn ->
  RawPlutusData ->
  Addr ->
  Coin ->
  TxBuild NoCtx Void ()
spendProgram validator paymentIn collateralIn scriptIn redeemer recipient spendCoin = do
  _ <- spend paymentIn
  collateral collateralIn
  attachScript validator
  _ <- spendScript scriptIn redeemer
  _ <- payTo recipient (inject spendCoin)
  pure ()

data NoCtx a
data Void = Void deriving (Show)

noCtxInterpretIO :: InterpretIO NoCtx
noCtxInterpretIO = InterpretIO $ \case {}

expectRight :: String -> Either String a -> IO a
expectRight label = \case
  Right value -> pure value
  Left err -> expectationFailure (label <> ": " <> err) >> fail err

expectRightShow :: (Show e) => String -> Either e a -> IO a
expectRightShow label = \case
  Right value -> pure value
  Left err -> expectationFailure (label <> ": " <> show err) >> fail label

waitForMatchingUtxo ::
  Provider IO ->
  Addr ->
  Int ->
  (TxOut ConwayEra -> Bool) ->
  IO (TxIn, TxOut ConwayEra)
waitForMatchingUtxo provider addr attempts predicate
  | attempts <= 0 =
      expectationFailure ("timed out waiting for matching UTxO at " <> show addr)
        >> fail "waitForMatchingUtxo"
  | otherwise = do
      utxos <- queryUTxOs provider addr
      case find (predicate . snd) utxos of
        Just utxo -> pure utxo
        Nothing -> do
          threadDelay 1_000_000
          waitForMatchingUtxo provider addr (attempts - 1) predicate

hasCoin :: Coin -> TxOut ConwayEra -> Bool
hasCoin coin txOut =
  txOut ^. coinTxOutL == coin && txOut ^. datumTxOutL == NoDatum

validatorAddr :: Script ConwayEra -> Addr
validatorAddr script =
  Addr Testnet (ScriptHashObj (hashScript @ConwayEra script)) StakeRefNull

txIdBytes :: TxId -> ByteString
txIdBytes (TxId safeHash) =
  hashToBytes (extractHash safeHash)

nonceFromTxIn :: TxIn -> ByteString
nonceFromTxIn (TxIn txId (TxIx txIx)) =
  convert (hash payload :: Digest Blake2b_256)
  where
    payload =
      BS.concat
        [ txIdBytes txId
        , toWord32BE txIx
        ]

toWord32BE :: Word16 -> ByteString
toWord32BE value =
  LBS.toStrict $
    BB.toLazyByteString $
      BB.word32BE (fromIntegral value)

newtype Blueprint = Blueprint
  { validators :: [ValidatorEntry]
  }

data ValidatorEntry = ValidatorEntry
  { title :: Text
  , compiledCode :: Maybe Text
  }

instance FromJSON Blueprint where
  parseJSON = withObject "Blueprint" $ \obj ->
    Blueprint <$> obj .: "validators"

instance FromJSON ValidatorEntry where
  parseJSON = withObject "ValidatorEntry" $ \obj ->
    ValidatorEntry
      <$> obj .: "title"
      <*> obj .:? "compiledCode"

loadBbsValidator :: FilePath -> IO (Script ConwayEra)
loadBbsValidator path = do
  blueprint <- either fail pure =<< (eitherDecodeFileStrict' path :: IO (Either String Blueprint))
  code <-
    case find (T.isPrefixOf "bbs_credential.bbs_credential.spend" . title) (validators blueprint)
      >>= compiledCode of
      Just hexText ->
        case decodeHexShort hexText of
          Just bytes -> pure bytes
          Nothing -> fail "invalid compiledCode hex in plutus.json"
      Nothing -> fail "bbs validator compiledCode missing in plutus.json"
  let plutus = Plutus @PlutusV3 (PlutusBinary code)
  case mkPlutusScript plutus of
    Just script -> pure (fromPlutusScript script)
    Nothing -> fail "invalid PlutusV3 script bytes in plutus.json"

decodeHexShort :: Text -> Maybe SBS.ShortByteString
decodeHexShort input
  | odd (T.length input) = Nothing
  | otherwise = SBS.toShort . BS.pack <$> go (T.unpack input)
  where
    go [] = Just []
    go (a : b : rest) = do
      hi <- hexDigit a
      lo <- hexDigit b
      (hi * 16 + lo :) <$> go rest
    go _ = Nothing

    hexDigit :: Char -> Maybe Word8
    hexDigit c
      | isDigit c = Just (fromIntegral (fromEnum c - fromEnum '0'))
      | c >= 'a' && c <= 'f' = Just (fromIntegral (fromEnum c - fromEnum 'a' + 10))
      | c >= 'A' && c <= 'F' = Just (fromIntegral (fromEnum c - fromEnum 'A' + 10))
      | otherwise = Nothing
