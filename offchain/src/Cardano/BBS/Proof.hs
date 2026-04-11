module Cardano.BBS.Proof (
  deriveProof,
  Proof (..),
  PresentationHeader (..),
) where

import Cardano.BBS.FFI (
  Attribute,
  Credential,
  DisclosureSet,
  Header,
  PresentationHeader (..),
  Proof (..),
  PublicKey,
  deriveProofBytes,
 )

deriveProof ::
  PublicKey ->
  Credential ->
  Maybe Header ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  IO Proof
deriveProof = deriveProofBytes
