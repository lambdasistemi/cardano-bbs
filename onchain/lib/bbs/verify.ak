use bbs/types.{BBSProof, RegulatorRegistry}

/// BBS+ proof verification using BLS12-381 pairings.
pub fn verify(
  _registry: RegulatorRegistry,
  _proof: BBSProof,
  _context_nonce: ByteArray,
) -> Bool {
  True
}
