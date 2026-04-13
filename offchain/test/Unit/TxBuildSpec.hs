{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Unit.TxBuildSpec (spec) where

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
import Cardano.BBS.TxBuild (
  proofRedeemerRawPlutusData,
  regulatorRegistryRawPlutusData,
 )
import Cardano.Crypto.Hash (
  Hash,
  HashAlgorithm,
  hashFromBytes,
 )
import Cardano.Ledger.Address (
  Addr (..),
 )
import Cardano.Ledger.Alonzo.TxWits (Redeemers (..))
import Cardano.Ledger.Api.PParams (emptyPParams)
import Cardano.Ledger.Api.Scripts.Data (Datum (NoDatum))
import Cardano.Ledger.Api.Tx (
  bodyTxL,
  witsTxL,
 )
import Cardano.Ledger.Api.Tx.Body (outputsTxBodyL)
import Cardano.Ledger.Api.Tx.Out (
  coinTxOutL,
  datumTxOutL,
 )
import Cardano.Ledger.Api.Tx.Wits (rdmrsTxWitsL)
import Cardano.Ledger.BaseTypes (
  Inject (inject),
  Network (Testnet),
  TxIx (..),
 )
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Credential (
  Credential (KeyHashObj),
  StakeReference (StakeRefNull),
 )
import Cardano.Ledger.Hashes (unsafeMakeSafeHash)
import Cardano.Ledger.Keys (
  KeyHash (..),
 )
import Cardano.Ledger.Mary.Value (MaryValue)
import Cardano.Ledger.TxIn (
  TxId (..),
  TxIn (..),
 )
import Cardano.Node.Client.TxBuild (
  draft,
  payTo',
  spendScript,
 )
import Data.ByteString qualified as BS
import Data.Foldable (toList)
import Data.Map.Strict qualified as Map
import Data.Word (Word8)
import Lens.Micro ((^.))
import Test.Hspec

spec :: Spec
spec =
  describe "Unit.TxBuildSpec" $
    it "bridges BBS datum and redeemer shapes into TxBuild" $ do
      (sk, pk) <- generateKeyPair
      let header = Just (Header "cardano-bbs-txbuild")
          attrs =
            [ Attribute "jurisdiction:EU"
            , Attribute "role:issuer"
            , Attribute "status:active"
            ]
          disclosed = [0, 2]
          ph = PresentationHeader "txbuild-nonce"
          outputValue :: MaryValue
          outputValue = inject (Coin 4000000)
      credential <- issueCredential sk pk header attrs
      proof <- deriveProof pk credential header ph attrs disclosed

      redeemer <- expectRight $ proofRedeemerRawPlutusData proof ph attrs disclosed
      let registry =
            regulatorRegistryRawPlutusData
              pk
              header
              ["jurisdiction", "role", "status"]
          tx =
            draft emptyPParams $ do
              _ <- spendScript (mkTxIn 1) redeemer
              _ <- payTo' (mkAddr 7) outputValue registry
              pure ()
          outputs = toList (tx ^. bodyTxL . outputsTxBodyL)

      case outputs of
        [output] -> do
          output ^. coinTxOutL `shouldBe` Coin 4000000
          output ^. datumTxOutL `shouldNotBe` NoDatum
        _ -> expectationFailure "expected exactly one TxOut"

      case tx ^. witsTxL . rdmrsTxWitsL of
        Redeemers redeemers -> Map.size redeemers `shouldBe` 1

mkHash32 ::
  (HashAlgorithm h) =>
  Word8 ->
  Hash h a
mkHash32 n =
  case hashFromBytes (BS.pack (replicate 31 0 ++ [n])) of
    Just h -> h
    Nothing -> error "mkHash32: impossible hash length"

mkHash28 ::
  (HashAlgorithm h) =>
  Word8 ->
  Hash h a
mkHash28 n =
  case hashFromBytes (BS.pack (replicate 27 0 ++ [n])) of
    Just h -> h
    Nothing -> error "mkHash28: impossible hash length"

mkTxIn :: Word8 -> TxIn
mkTxIn n =
  TxIn
    (TxId $ unsafeMakeSafeHash $ mkHash32 n)
    (TxIx (fromIntegral n))

mkAddr :: Word8 -> Addr
mkAddr n =
  Addr
    Testnet
    (KeyHashObj (KeyHash (mkHash28 n)))
    StakeRefNull

expectRight :: Either String a -> IO a
expectRight = \case
  Right value -> pure value
  Left err -> expectationFailure err >> fail err
