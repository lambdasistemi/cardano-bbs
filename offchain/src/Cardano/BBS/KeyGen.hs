module Cardano.BBS.KeyGen (
  generateKeyPair,
  SecretKey (..),
  PublicKey (..),
) where

import Cardano.BBS.FFI (
  PublicKey (..),
  SecretKey (..),
  generateKeyPair,
 )
