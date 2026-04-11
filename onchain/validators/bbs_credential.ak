use bbs/types.{BBSProof, RegulatorRegistry}
use bbs/verify
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction}

/// BBS+ credential validator.
validator bbs_credential {
  spend(
    datum: Option<RegulatorRegistry>,
    redeemer: BBSProof,
    _own_ref: OutputReference,
    _self: Transaction,
  ) {
    expect Some(registry) = datum
    verify.verify(registry, redeemer, #"")
  }

  else(_ctx: ScriptContext) {
    False
  }
}
