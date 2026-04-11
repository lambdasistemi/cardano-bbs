/// BBS+ data types for on-chain verification.
pub type G1Element {
  bytes: ByteArray,
}

pub type G2Element {
  bytes: ByteArray,
}

pub type BBSProof {
  a_bar: G1Element,
  b_bar: G1Element,
  d: G1Element,
  e_hat: ByteArray,
  r1_hat: ByteArray,
  r3_hat: ByteArray,
  m_hat: List<ByteArray>,
  c: ByteArray,
  disclosed_indices: List<Int>,
  disclosed_values: List<ByteArray>,
  nonce: ByteArray,
}

pub type RegulatorRegistry {
  regulator_pk: G2Element,
  credential_schema: List<ByteArray>,
}
