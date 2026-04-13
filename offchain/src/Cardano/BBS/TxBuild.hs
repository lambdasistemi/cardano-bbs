{-# LANGUAGE LambdaCase #-}

-- | Helpers for using serialized BBS data with Cardano transaction builders.
module Cardano.BBS.TxBuild (
  RawPlutusData (..),
  toRawPlutusData,
  proofRedeemerRawPlutusData,
  regulatorRegistryRawPlutusData,
) where

import Cardano.BBS.FFI (
  Attribute,
  DisclosureSet,
  Header,
  PresentationHeader,
  Proof,
  PublicKey,
 )
import Cardano.BBS.Serialize (
  PlutusData (..),
  bbsProofDatumToData,
  proofRedeemerData,
  regulatorRegistryData,
  regulatorRegistryDatumToData,
 )
import Data.ByteString (ByteString)
import qualified PlutusCore.Data as PLC
import PlutusTx.Builtins.Internal (BuiltinData (..))
import PlutusTx.IsData.Class (ToData (..))

newtype RawPlutusData = RawPlutusData PLC.Data
  deriving (Eq, Show)

instance ToData RawPlutusData where
  toBuiltinData (RawPlutusData datum) = BuiltinData datum

toRawPlutusData :: PlutusData -> RawPlutusData
toRawPlutusData = RawPlutusData . plutusDataToPLC

proofRedeemerRawPlutusData ::
  Proof ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  Either String RawPlutusData
proofRedeemerRawPlutusData proof ph attrs disclosed =
  toRawPlutusData . bbsProofDatumToData
    <$> proofRedeemerData proof ph attrs disclosed

regulatorRegistryRawPlutusData ::
  PublicKey ->
  Maybe Header ->
  [ByteString] ->
  RawPlutusData
regulatorRegistryRawPlutusData pk mHeader =
  toRawPlutusData . regulatorRegistryDatumToData . regulatorRegistryData pk mHeader

plutusDataToPLC :: PlutusData -> PLC.Data
plutusDataToPLC = \case
  Constr tag fields -> PLC.Constr tag (plutusDataToPLC <$> fields)
  Map entries -> PLC.Map [(plutusDataToPLC k, plutusDataToPLC v) | (k, v) <- entries]
  List values -> PLC.List (plutusDataToPLC <$> values)
  Integer n -> PLC.I n
  Bytes bytes -> PLC.B bytes
