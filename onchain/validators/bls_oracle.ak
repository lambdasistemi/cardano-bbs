use bls/aggregate
use bls/types.{AggregateSignatureRedeemer, OracleRegistry}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction}

/// BLS multi-oracle validator.
validator bls_oracle {
  spend(
    datum: Option<OracleRegistry>,
    redeemer: AggregateSignatureRedeemer,
    _own_ref: OutputReference,
    _self: Transaction,
  ) {
    expect Some(registry) = datum
    aggregate.verify(registry, redeemer)
  }

  else(_ctx: ScriptContext) {
    False
  }
}
