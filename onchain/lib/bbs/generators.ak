use bbs/types.{G1Element}

/// Generator point computation for BBS+.
pub fn message_generator(_index: Int) -> G1Element {
  G1Element { bytes: #"00" }
}
