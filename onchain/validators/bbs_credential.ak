use bbs/types.{BBSProof, G1Element, G2Element, RegulatorRegistry}
use bbs/verify
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction, placeholder}

/// BBS+ credential validator.
validator bbs_credential {
  spend(
    datum: Option<RegulatorRegistry>,
    redeemer: BBSProof,
    _own_ref: OutputReference,
    self: Transaction,
  ) {
    when datum is {
      Some(registry) -> verify.verify(registry, redeemer, self.id)
      None -> False
    }
  }

  else(_ctx: ScriptContext) {
    False
  }
}

test spend_accepts_structurally_valid_tx_bound_proof() {
  let registry = sample_registry()
  let self = Transaction { ..placeholder, id: #"ab" }
  let proof = sample_proof(#"ab")

  bbs_credential.spend(Some(registry), proof, sample_output_reference(), self)
}

test spend_rejects_wrong_transaction_nonce() {
  let registry = sample_registry()
  let self = Transaction { ..placeholder, id: #"ab" }
  let proof = sample_proof(#"cd")

  !bbs_credential.spend(Some(registry), proof, sample_output_reference(), self)
}

test spend_rejects_missing_datum() {
  let self = Transaction { ..placeholder, id: #"ab" }
  let proof = sample_proof(#"ab")

  !bbs_credential.spend(None, proof, sample_output_reference(), self)
}

fn sample_registry() -> RegulatorRegistry {
  verify.normalize_registry(
    RegulatorRegistry {
      regulator_pk: G2Element { bytes: #"11" },
      credential_schema: [
        #"6a7572697364696374696f6e", #"726f6c65", #"737461747573",
      ],
    },
  )
}

fn sample_proof(nonce: ByteArray) -> BBSProof {
  verify.normalize_proof(
    BBSProof {
      a_bar: G1Element { bytes: #"01" },
      b_bar: G1Element { bytes: #"02" },
      d: G1Element { bytes: #"03" },
      e_hat: #"10",
      r1_hat: #"11",
      r3_hat: #"12",
      m_hat: [#"13"],
      c: #"14",
      disclosed_indices: [0, 2],
      disclosed_values: [#"4555", #"616374697665"],
      nonce,
    },
  )
}

fn sample_output_reference() -> OutputReference {
  OutputReference {
    transaction_id: #"ef00000000000000000000000000000000000000000000000000000000000000",
    output_index: 0,
  }
}
