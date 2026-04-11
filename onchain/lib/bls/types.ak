use bbs/types.{G1Element, G2Element}

/// BLS aggregate signature types.
pub type AggregateSignatureRedeemer {
  signature: G1Element,
  message: ByteArray,
  signer_indices: List<Int>,
}

pub type OracleRegistry {
  oracle_pks: List<G2Element>,
  quorum: Int,
}
