module Cardano.BBS.Verify (
  verifyCredential,
  verifyProof,
) where

import Cardano.BBS.FFI (
  Attribute,
  DisclosureSet,
  Header,
  PresentationHeader,
  Proof,
  PublicKey,
  verifyCredential,
  verifyProofBytes,
 )

verifyProof ::
  PublicKey ->
  Maybe Header ->
  PresentationHeader ->
  [Attribute] ->
  DisclosureSet ->
  Proof ->
  IO Bool
verifyProof = verifyProofBytes
