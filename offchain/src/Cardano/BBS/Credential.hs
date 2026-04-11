module Cardano.BBS.Credential (
  issueCredential,
  Credential (..),
  Attribute (..),
  Header (..),
) where

import Cardano.BBS.FFI (
  Attribute (..),
  Credential (..),
  Header (..),
  PublicKey,
  SecretKey,
  signCredential,
 )

issueCredential :: SecretKey -> PublicKey -> Maybe Header -> [Attribute] -> IO Credential
issueCredential = signCredential
