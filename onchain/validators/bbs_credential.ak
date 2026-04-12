use aiken/collection/list
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
  let self = Transaction {
    ..placeholder,
    id: #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  }
  let proof = sample_proof()

  bbs_credential.spend(Some(registry), proof, sample_output_reference(), self)
}

test spend_accepts_partial_disclosure_proof() {
  let registry = sample_registry()
  let self = Transaction {
    ..placeholder,
    id: #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  }
  let proof = sample_proof()

  and {
    proof.disclosed_indices == [0, 2, 4, 6],
    proof.disclosed_values == [
      #"9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
      #"7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73",
      #"496694774c5604ab1b2544eababcf0f53278ff50", #"d183ddc6e2665aa4e2f088af",
    ],
    list.length(proof.m_hat) == 6,
    bbs_credential.spend(Some(registry), proof, sample_output_reference(), self),
  }
}

test spend_rejects_wrong_transaction_nonce() {
  let registry = sample_registry()
  let self = Transaction { ..placeholder, id: #"00112233" }
  let proof = sample_proof()

  !bbs_credential.spend(Some(registry), proof, sample_output_reference(), self)
}

test spend_rejects_missing_datum() {
  let self = Transaction {
    ..placeholder,
    id: #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  }
  let proof = sample_proof()

  !bbs_credential.spend(None, proof, sample_output_reference(), self)
}

fn sample_registry() -> RegulatorRegistry {
  RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c",
    },
    credential_schema: [
      #"6d30", #"6d31", #"6d32", #"6d33", #"6d34", #"6d35", #"6d36", #"6d37",
      #"6d38", #"6d39",
    ],
  }
}

fn sample_proof() -> BBSProof {
  BBSProof {
    a_bar: G1Element {
      bytes: #"81925c2e525d9fbb0ba95b438b5a13fff5874c7c0515c193628d7d143ddc3bb487771ad73658895997a88dd5b254ed29",
    },
    b_bar: G1Element {
      bytes: #"abc019bfca62c09b8dafb37e5f09b1d380e084ec3623d071ec38d6b8602af93aa0ddbada307c9309cca86be16db53dc7",
    },
    d: G1Element {
      bytes: #"ac310574f509c712bb1a181d64ea3c1ee075c018a2bc773e2480b5c033ccb9bfea5af347a88ab83746c9342ba76db367",
    },
    e_hat: #"5ff70ce9006d166fd813a81b448a632216521c864594f3f92965974914992f8d",
    r1_hat: #"1845230915b11680cf44b25886c5670904ac2d88255c8c31aea7b072e9c4eb7e",
    r3_hat: #"4c3fdd38836ae9d2e9fa271c8d9fd42f669a9938aeeba9d8ae613bf11f489ce9",
    m_hat: [
      #"47616f5cbaee95511dfaa5c73d85e4ddd2f29340f821dc2fb40db3eae5f5bc08",
      #"467eb195e38d7d436b63e556ea653168282a23b53d5792a107f85b1203f82aab",
      #"46f6940650760e5b320261ffc0ca5f15917b51e7d2ad4bcbec94de792e229db6",
      #"63abff23af392a5e73ce115c27e8492ec24a0815091c69874dbd9dae2d2eed00",
      #"0810c748a798a78a804a39034c6e745cee455812cc982eea7105948b2cb55b82",
      #"278a77237fcbec4748e2d2255af0994dd09dba8ac60515a39b24632a2c1c840c",
    ],
    c: #"4a70506add5b2eb0be9ff66e3ea8deae666f198edfbb1391c6834e6df4f1026d",
    disclosed_indices: [0, 2, 4, 6],
    disclosed_values: [
      #"9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
      #"7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73",
      #"496694774c5604ab1b2544eababcf0f53278ff50", #"d183ddc6e2665aa4e2f088af",
    ],
    nonce: #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  }
}

fn sample_output_reference() -> OutputReference {
  OutputReference {
    transaction_id: #"ef00000000000000000000000000000000000000000000000000000000000000",
    output_index: 0,
  }
}
