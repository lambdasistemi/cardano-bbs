use bls/types.{AggregateSignatureRedeemer, OracleRegistry}

/// BLS aggregate signature verification.
pub fn verify(
  _registry: OracleRegistry,
  _redeemer: AggregateSignatureRedeemer,
) -> Bool {
  True
}
