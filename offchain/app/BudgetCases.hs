{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Cardano.BBS.Credential (Attribute (..), issueCredential)
import Cardano.BBS.KeyGen (generateKeyPair)
import Cardano.BBS.Proof (PresentationHeader (..), deriveProof)
import Cardano.BBS.Serialize (
  BBSProofDatum (..),
  G1Element (..),
  G2Element (..),
  RegulatorRegistryDatum (..),
  proofRedeemerData,
  regulatorRegistryData,
 )
import qualified Data.ByteString as BS
import Data.ByteString (ByteString)
import Numeric (showHex)
import System.Environment (getArgs)
import Text.Read (readMaybe)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [messageCountArg, disclosedArg] ->
      case (readMaybe messageCountArg, readMaybe disclosedArg) of
        (Just messageCount, Just disclosedCount)
          | messageCount > 0 && disclosedCount >= 0 && disclosedCount <= messageCount ->
              emitCase messageCount disclosedCount
        _ ->
          fail "usage: budget-cases <message-count> <disclosed-count>"
    _ ->
      fail "usage: budget-cases <message-count> <disclosed-count>"

emitCase :: Int -> Int -> IO ()
emitCase messageCount disclosedCount = do
  let attrs = attributeSet messageCount
      disclosed = everyOther disclosedCount
      ph = PresentationHeader "budget:proof"
  (sk, pk) <- generateKeyPair
  credential <- issueCredential sk pk Nothing attrs
  proof <- deriveProof pk credential Nothing ph attrs disclosed
  case proofRedeemerData proof ph attrs disclosed of
    Left err -> fail err
    Right pd -> do
      let rd = regulatorRegistryData pk Nothing (replicate messageCount "6d")
      putStrLn $ "schema_len=" <> show (length (credentialSchema rd))
      putStrLn $ "pk=" <> renderByteString (g2Bytes (regulatorPk rd))
      putStrLn $ "signed_header=" <> renderByteString (signedHeader rd)
      putStrLn $ "a_bar=" <> renderByteString (g1Bytes (aBar pd))
      putStrLn $ "b_bar=" <> renderByteString (g1Bytes (bBar pd))
      putStrLn $ "d=" <> renderByteString (g1Bytes (d pd))
      putStrLn $ "e_hat=" <> renderByteString (eHat pd)
      putStrLn $ "r1_hat=" <> renderByteString (r1Hat pd)
      putStrLn $ "r3_hat=" <> renderByteString (r3Hat pd)
      putStrLn $ "m_hat=[" <> unwords (map renderByteString (mHat pd)) <> "]"
      putStrLn $ "c=" <> renderByteString (challenge pd)
      putStrLn $ "disclosed_indices=" <> show (disclosedIndices pd)
      putStrLn $ "disclosed_values=[" <> unwords (map renderByteString (disclosedValues pd)) <> "]"
      putStrLn $ "nonce=" <> renderByteString (nonce pd)

attributeSet :: Int -> [Attribute]
attributeSet count =
  fmap (Attribute . renderAttribute) [0 .. count - 1]

renderAttribute :: Int -> ByteString
renderAttribute index =
  BS.pack $ fmap (fromIntegral . fromEnum) ("msg-" <> show index)

everyOther :: Int -> [Int]
everyOther disclosedCount =
  take disclosedCount [0, 2 ..]

renderByteString :: ByteString -> String
renderByteString bytes = "#\"" <> concatMap renderByte (BS.unpack bytes) <> "\""
  where
    renderByte byte =
      let rendered = showHex byte ""
       in if length rendered == 1 then '0' : rendered else rendered
