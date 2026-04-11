{-# LANGUAGE LambdaCase #-}

-- | CBOR serialization for BBS+ data structures, matching Aiken's Plutus Data shape.
module Cardano.BBS.Serialize (
  PlutusData (..),
  G1Element (..),
  G2Element (..),
  BBSProofDatum (..),
  RegulatorRegistryDatum (..),
  proofRedeemerData,
  proofRedeemerToCBOR,
  publicKeyData,
  publicKeyToCBOR,
  regulatorRegistryData,
  regulatorRegistryToCBOR,
  encodePlutusData,
  decodePlutusData,
) where

import Cardano.BBS.FFI (
  Attribute (..),
  DisclosureSet,
  PresentationHeader (..),
  Proof (..),
  PublicKey (..),
 )
import Codec.CBOR.Decoding (
  Decoder,
  TokenType (
    TypeBytes,
    TypeListLen,
    TypeListLen64,
    TypeMapLen,
    TypeMapLen64,
    TypeNInt,
    TypeNInt64,
    TypeTag,
    TypeUInt,
    TypeUInt64
  ),
  decodeBytes,
  decodeInteger,
  decodeListLen,
  decodeMapLen,
  decodeTag,
  peekTokenType,
 )
import Codec.CBOR.Encoding (
  Encoding,
  encodeBytes,
  encodeInteger,
  encodeListLen,
  encodeMapLen,
  encodeTag,
 )
import Codec.CBOR.Read (deserialiseFromBytes)
import Codec.CBOR.Write (toStrictByteString)
import Control.Monad (replicateM)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.List (sort)
import qualified Data.Set as Set

data PlutusData
  = Constr Integer [PlutusData]
  | Map [(PlutusData, PlutusData)]
  | List [PlutusData]
  | Integer Integer
  | Bytes ByteString
  deriving (Eq, Show)

newtype G1Element = G1Element {g1Bytes :: ByteString}
  deriving (Eq, Show)

newtype G2Element = G2Element {g2Bytes :: ByteString}
  deriving (Eq, Show)

data BBSProofDatum = BBSProofDatum
  { aBar :: G1Element
  , bBar :: G1Element
  , d :: G1Element
  , eHat :: ByteString
  , r1Hat :: ByteString
  , r3Hat :: ByteString
  , mHat :: [ByteString]
  , challenge :: ByteString
  , disclosedIndices :: [Int]
  , disclosedValues :: [ByteString]
  , nonce :: ByteString
  }
  deriving (Eq, Show)

data RegulatorRegistryDatum = RegulatorRegistryDatum
  { regulatorPk :: G2Element
  , credentialSchema :: [ByteString]
  }
  deriving (Eq, Show)

g1CompressedBytes :: Int
g1CompressedBytes = 48

scalarBytes :: Int
scalarBytes = 32

proofRedeemerData ::
  Proof ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  Either String BBSProofDatum
proofRedeemerData (Proof bytes) (PresentationHeader ph) attrs disclosed = do
  disclosed' <- validateDisclosureSet (length attrs) disclosed
  let hiddenCount = length attrs - length disclosed'
  (aBarBytes, rest1) <- splitExact "a_bar" g1CompressedBytes bytes
  (bBarBytes, rest2) <- splitExact "b_bar" g1CompressedBytes rest1
  (dBytes, rest3) <- splitExact "d" g1CompressedBytes rest2
  (eHatBytes, rest4) <- splitExact "e_hat" scalarBytes rest3
  (r1HatBytes, rest5) <- splitExact "r1_hat" scalarBytes rest4
  (r3HatBytes, rest6) <- splitExact "r3_hat" scalarBytes rest5
  (mHatBytes, rest7) <- splitManyExact "m_hat" hiddenCount scalarBytes rest6
  (challengeBytes, rest8) <- splitExact "c" scalarBytes rest7
  if BS.null rest8
    then
      Right
        BBSProofDatum
          { aBar = G1Element aBarBytes
          , bBar = G1Element bBarBytes
          , d = G1Element dBytes
          , eHat = eHatBytes
          , r1Hat = r1HatBytes
          , r3Hat = r3HatBytes
          , mHat = mHatBytes
          , challenge = challengeBytes
          , disclosedIndices = disclosed'
          , disclosedValues = disclosedAttributeValues attrs disclosed'
          , nonce = ph
          }
    else
      Left "proof bytes contain trailing data"

proofRedeemerToCBOR ::
  Proof ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  Either String ByteString
proofRedeemerToCBOR proof ph attrs disclosed =
  encodePlutusData . bbsProofDatumToData <$> proofRedeemerData proof ph attrs disclosed

publicKeyData :: PublicKey -> G2Element
publicKeyData (PublicKey pkBytes) = G2Element pkBytes

publicKeyToCBOR :: PublicKey -> ByteString
publicKeyToCBOR = encodePlutusData . g2ElementToData . publicKeyData

regulatorRegistryData :: PublicKey -> [ByteString] -> RegulatorRegistryDatum
regulatorRegistryData (PublicKey pkBytes) schema =
  RegulatorRegistryDatum
    { regulatorPk = G2Element pkBytes
    , credentialSchema = schema
    }

regulatorRegistryToCBOR :: PublicKey -> [ByteString] -> ByteString
regulatorRegistryToCBOR pk =
  encodePlutusData . regulatorRegistryDatumToData . regulatorRegistryData pk

encodePlutusData :: PlutusData -> ByteString
encodePlutusData = toStrictByteString . encodeData

decodePlutusData :: ByteString -> Either String PlutusData
decodePlutusData bytes = do
  (_, value) <- firstShow $ deserialiseFromBytes decodeData (LBS.fromStrict bytes)
  pure value

bbsProofDatumToData :: BBSProofDatum -> PlutusData
bbsProofDatumToData proof =
  Constr
    0
    [ g1ElementToData (aBar proof)
    , g1ElementToData (bBar proof)
    , g1ElementToData (d proof)
    , Bytes (eHat proof)
    , Bytes (r1Hat proof)
    , Bytes (r3Hat proof)
    , List (Bytes <$> mHat proof)
    , Bytes (challenge proof)
    , List (Integer . fromIntegral <$> disclosedIndices proof)
    , List (Bytes <$> disclosedValues proof)
    , Bytes (nonce proof)
    ]

regulatorRegistryDatumToData :: RegulatorRegistryDatum -> PlutusData
regulatorRegistryDatumToData registry =
  Constr
    0
    [ g2ElementToData (regulatorPk registry)
    , List (Bytes <$> credentialSchema registry)
    ]

g1ElementToData :: G1Element -> PlutusData
g1ElementToData (G1Element bytes) = Constr 0 [Bytes bytes]

g2ElementToData :: G2Element -> PlutusData
g2ElementToData (G2Element bytes) = Constr 0 [Bytes bytes]

encodeData :: PlutusData -> Encoding
encodeData = \case
  Constr tag fields ->
    encodeConstr tag <> encodeList fields
  Map entries ->
    encodeMapLen (fromIntegral (length entries))
      <> foldMap (\(k, v) -> encodeData k <> encodeData v) entries
  List values ->
    encodeList values
  Integer n ->
    encodeInteger n
  Bytes bytes ->
    encodeBytes bytes

encodeList :: [PlutusData] -> Encoding
encodeList values =
  encodeListLen (fromIntegral (length values))
    <> foldMap encodeData values

encodeConstr :: Integer -> Encoding
encodeConstr tag
  | 0 <= tag && tag <= 6 = encodeTag (121 + fromIntegral tag)
  | 7 <= tag && tag <= 127 = encodeTag (1280 + fromIntegral (tag - 7))
  | otherwise = encodeTag 102 <> encodeListLen 2 <> encodeInteger tag

decodeData :: Decoder s PlutusData
decodeData =
  peekTokenType >>= \case
    TypeTag -> decodeConstr
    TypeMapLen -> decodeMap
    TypeMapLen64 -> decodeMap
    TypeListLen -> decodeList
    TypeListLen64 -> decodeList
    TypeBytes -> Bytes <$> decodeBytes
    TypeUInt -> Integer <$> decodeInteger
    TypeUInt64 -> Integer <$> decodeInteger
    TypeNInt -> Integer <$> decodeInteger
    TypeNInt64 -> Integer <$> decodeInteger
    other -> fail ("unsupported CBOR token for plutus data: " <> show other)

decodeConstr :: Decoder s PlutusData
decodeConstr = do
  tag <- decodeTag
  case tag of
    n
      | 121 <= n && n <= 127 ->
          Constr (fromIntegral (n - 121)) <$> decodeListPayload
    n
      | 1280 <= n && n <= 1400 ->
          Constr (fromIntegral (n - 1280 + 7)) <$> decodeListPayload
    102 -> do
      len <- decodeListLen
      if len /= 2
        then fail "constructor tag 102 must be followed by a 2-element list"
        else do
          ix <- decodeInteger
          fields <-
            decodeData >>= \case
              List xs -> pure xs
              _ -> fail "constructor tag 102 payload must contain a list of fields"
          pure $ Constr ix fields
    _ -> fail ("unsupported constructor tag: " <> show tag)

decodeMap :: Decoder s PlutusData
decodeMap = do
  len <- decodeMapLen
  entries <- replicateM len ((,) <$> decodeData <*> decodeData)
  pure $ Map entries

decodeList :: Decoder s PlutusData
decodeList = List <$> decodeListPayload

decodeListPayload :: Decoder s [PlutusData]
decodeListPayload = do
  len <- decodeListLen
  replicateM len decodeData

validateDisclosureSet :: Int -> DisclosureSet -> Either String [Int]
validateDisclosureSet total disclosed
  | any (< 0) disclosed = Left "disclosure set contains a negative index"
  | any (>= total) disclosed = Left "disclosure set contains an out-of-bounds index"
  | Set.size disclosedSet /= length disclosed = Left "disclosure set contains duplicate indices"
  | disclosed /= disclosedSorted = Left "disclosure set must be sorted in ascending order"
  | otherwise = Right disclosed
  where
    disclosedSet = Set.fromList disclosed
    disclosedSorted = sort disclosed

disclosedAttributeValues :: [Attribute] -> [Int] -> [ByteString]
disclosedAttributeValues attrs =
  fmap (\ix -> unAttribute (attrs !! ix))

splitExact :: String -> Int -> ByteString -> Either String (ByteString, ByteString)
splitExact label size bytes
  | BS.length bytes < size = Left ("proof bytes truncated while reading " <> label)
  | otherwise = Right (BS.take size bytes, BS.drop size bytes)

splitManyExact ::
  String ->
  Int ->
  Int ->
  ByteString ->
  Either String ([ByteString], ByteString)
splitManyExact label count size bytes =
  foldl' step (Right ([], bytes)) [1 .. count]
  where
    step :: Either String ([ByteString], ByteString) -> Int -> Either String ([ByteString], ByteString)
    step acc _ = do
      (chunks, rest) <- acc
      (chunk, rest') <- splitExact label size rest
      pure (chunks <> [chunk], rest')

firstShow :: (Show e) => Either e a -> Either String a
firstShow = either (Left . show) Right
