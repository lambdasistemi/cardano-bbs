{-# LANGUAGE ForeignFunctionInterface #-}

module Cardano.BBS.FFI (
  SecretKey (..),
  PublicKey (..),
  Credential (..),
  Proof (..),
  Header (..),
  PresentationHeader (..),
  Attribute (..),
  DisclosureSet,
  secretKeyBytes,
  publicKeyBytes,
  signatureBytes,
  generateKeyPair,
  signCredential,
  verifyCredential,
  deriveProofBytes,
  verifyProofBytes,
) where

import Data.Binary.Put (putWord32be, putWord8, runPut)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Coerce (coerce)
import Data.Word (Word8)
import Foreign.C.String (CString, peekCString)
import Foreign.C.Types (CInt (..))
import Foreign.Marshal.Alloc (alloca)
import Foreign.Marshal.Array (allocaArray)
import Foreign.Ptr (Ptr, nullPtr)
import Foreign.Storable (peek)
import System.IO.Unsafe (unsafePerformIO)

newtype SecretKey = SecretKey {unSecretKey :: ByteString}
  deriving (Eq, Show)

newtype PublicKey = PublicKey {unPublicKey :: ByteString}
  deriving (Eq, Show)

newtype Credential = Credential {unCredential :: ByteString}
  deriving (Eq, Show)

newtype Proof = Proof {unProof :: ByteString}
  deriving (Eq, Show)

newtype Header = Header {unHeader :: ByteString}
  deriving (Eq, Show)

newtype PresentationHeader = PresentationHeader {unPresentationHeader :: ByteString}
  deriving (Eq, Show)

newtype Attribute = Attribute {unAttribute :: ByteString}
  deriving (Eq, Show)

type DisclosureSet = [Int]

foreign import ccall unsafe "bbs_secret_key_bytes"
  c_secretKeyBytes :: IO Int

foreign import ccall unsafe "bbs_public_key_bytes"
  c_publicKeyBytes :: IO Int

foreign import ccall unsafe "bbs_signature_bytes"
  c_signatureBytes :: IO Int

foreign import ccall unsafe "bbs_last_error"
  c_lastError :: IO CString

foreign import ccall safe "bbs_bls12_381_sha_256_keygen"
  c_keygen :: Ptr Word8 -> Int -> Ptr Word8 -> Int -> IO CInt

foreign import ccall safe "bbs_bls12_381_sha_256_sign"
  c_sign ::
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    IO CInt

foreign import ccall safe "bbs_bls12_381_sha_256_verify"
  c_verify ::
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    IO CInt

foreign import ccall safe "bbs_bls12_381_sha_256_proof_gen"
  c_proofGen ::
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Int ->
    IO CInt

foreign import ccall safe "bbs_bls12_381_sha_256_proof_verify"
  c_proofVerify ::
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    Ptr Word8 ->
    Int ->
    IO CInt

secretKeyBytes :: Int
secretKeyBytes = unsafePerformIO c_secretKeyBytes
{-# NOINLINE secretKeyBytes #-}

publicKeyBytes :: Int
publicKeyBytes = unsafePerformIO c_publicKeyBytes
{-# NOINLINE publicKeyBytes #-}

signatureBytes :: Int
signatureBytes = unsafePerformIO c_signatureBytes
{-# NOINLINE signatureBytes #-}

proofBytesFor :: Int -> Int -> Int
proofBytesFor totalMessages disclosedCount =
  272 + 32 * max 0 (totalMessages - disclosedCount)

ffiError :: String -> IO a
ffiError context = do
  cstr <- c_lastError
  message <-
    if cstr == nullPtr
      then pure "unknown ffi failure"
      else peekCString cstr
  ioError $ userError (context <> ": " <> message)

withOptionalBytes :: Maybe ByteString -> (Ptr Word8 -> Int -> IO a) -> IO a
withOptionalBytes Nothing action = action nullPtr 0
withOptionalBytes (Just bytes) action =
  BS.useAsCStringLen bytes $ \(ptr, len) -> action (coerce ptr) len

encodeFrames :: [ByteString] -> ByteString
encodeFrames frames =
  LBS.toStrict $
    runPut $ do
      putWord32be (fromIntegral (length frames))
      mapM_
        ( \frame -> do
            putWord32be (fromIntegral (BS.length frame))
            mapM_ putWord8 (BS.unpack frame)
        )
        frames

encodeDisclosureSet :: DisclosureSet -> ByteString
encodeDisclosureSet =
  encodeFrames . fmap (LBS.toStrict . runPut . putWord32be . fromIntegral)

withFramedMessages :: [ByteString] -> (Ptr Word8 -> Int -> IO a) -> IO a
withFramedMessages messages =
  let payload = encodeFrames messages
   in \action -> BS.useAsCStringLen payload $ \(ptr, len) -> action (coerce ptr) len

withDisclosureSet :: DisclosureSet -> (Ptr Word8 -> Int -> IO a) -> IO a
withDisclosureSet disclosure =
  let payload = encodeDisclosureSet disclosure
   in \action -> BS.useAsCStringLen payload $ \(ptr, len) -> action (coerce ptr) len

generateKeyPair :: IO (SecretKey, PublicKey)
generateKeyPair =
  allocaArray secretKeyBytes $ \skPtr ->
    allocaArray publicKeyBytes $ \pkPtr -> do
      rc <- c_keygen skPtr secretKeyBytes pkPtr publicKeyBytes
      if rc == 0
        then do
          sk <- BS.packCStringLen (coerce skPtr, secretKeyBytes)
          pk <- BS.packCStringLen (coerce pkPtr, publicKeyBytes)
          pure (SecretKey sk, PublicKey pk)
        else ffiError "bbs keygen"

signCredential :: SecretKey -> PublicKey -> Maybe Header -> [Attribute] -> IO Credential
signCredential (SecretKey sk) (PublicKey pk) mHeader attrs =
  BS.useAsCStringLen sk $ \(skPtr, skLen) ->
    BS.useAsCStringLen pk $ \(pkPtr, pkLen) ->
      withOptionalBytes (unHeader <$> mHeader) $ \headerPtr headerLen ->
        withFramedMessages (unAttribute <$> attrs) $ \msgsPtr msgsLen ->
          allocaArray signatureBytes $ \sigPtr -> do
            rc <-
              c_sign
                (coerce skPtr)
                skLen
                (coerce pkPtr)
                pkLen
                headerPtr
                headerLen
                msgsPtr
                msgsLen
                sigPtr
                signatureBytes
            if rc == 0
              then Credential <$> BS.packCStringLen (coerce sigPtr, signatureBytes)
              else ffiError "bbs sign"

verifyCredential :: PublicKey -> Maybe Header -> [Attribute] -> Credential -> IO Bool
verifyCredential (PublicKey pk) mHeader attrs (Credential sig) =
  BS.useAsCStringLen pk $ \(pkPtr, pkLen) ->
    withOptionalBytes (unHeader <$> mHeader) $ \headerPtr headerLen ->
      withFramedMessages (unAttribute <$> attrs) $ \msgsPtr msgsLen ->
        BS.useAsCStringLen sig $ \(sigPtr, sigLen) -> do
          rc <-
            c_verify
              (coerce pkPtr)
              pkLen
              headerPtr
              headerLen
              msgsPtr
              msgsLen
              (coerce sigPtr)
              sigLen
          pure (rc == 0)

deriveProofBytes ::
  PublicKey ->
  Credential ->
  Maybe Header ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  IO Proof
deriveProofBytes (PublicKey pk) (Credential sig) mHeader (PresentationHeader ph) attrs disclosed =
  BS.useAsCStringLen pk $ \(pkPtr, pkLen) ->
    BS.useAsCStringLen sig $ \(sigPtr, sigLen) ->
      withOptionalBytes (unHeader <$> mHeader) $ \headerPtr headerLen ->
        BS.useAsCStringLen ph $ \(phPtr, phLen) ->
          withFramedMessages (unAttribute <$> attrs) $ \msgsPtr msgsLen ->
            withDisclosureSet disclosed $ \disclosedPtr disclosedLen -> do
              let proofSize = proofBytesFor (length attrs) (length disclosed)
              allocaArray proofSize $ \proofPtr ->
                alloca $ \writtenPtr -> do
                  rc <-
                    c_proofGen
                      (coerce pkPtr)
                      pkLen
                      (coerce sigPtr)
                      sigLen
                      headerPtr
                      headerLen
                      (coerce phPtr)
                      phLen
                      msgsPtr
                      msgsLen
                      disclosedPtr
                      disclosedLen
                      proofPtr
                      proofSize
                      writtenPtr
                  if rc == 0
                    then do
                      written <- peek writtenPtr
                      Proof <$> BS.packCStringLen (coerce proofPtr, written)
                    else ffiError "bbs proof gen"

verifyProofBytes ::
  PublicKey ->
  Maybe Header ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  Proof ->
  IO Bool
verifyProofBytes (PublicKey pk) mHeader (PresentationHeader ph) disclosedAttrs disclosed (Proof proof) =
  BS.useAsCStringLen pk $ \(pkPtr, pkLen) ->
    withOptionalBytes (unHeader <$> mHeader) $ \headerPtr headerLen ->
      BS.useAsCStringLen ph $ \(phPtr, phLen) ->
        withFramedMessages (unAttribute <$> disclosedAttrs) $ \msgsPtr msgsLen ->
          withDisclosureSet disclosed $ \disclosedPtr disclosedLen ->
            BS.useAsCStringLen proof $ \(proofPtr, proofLen) -> do
              rc <-
                c_proofVerify
                  (coerce pkPtr)
                  pkLen
                  headerPtr
                  headerLen
                  (coerce phPtr)
                  phLen
                  msgsPtr
                  msgsLen
                  disclosedPtr
                  disclosedLen
                  (coerce proofPtr)
                  proofLen
              pure (rc == 0)
