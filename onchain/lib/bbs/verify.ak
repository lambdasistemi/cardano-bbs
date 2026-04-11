use aiken/collection/list
use aiken/primitive/bytearray
use bbs/types.{BBSProof, G1Element, G2Element, RegulatorRegistry}

const compressed_g1_bytes = 48

const compressed_g2_bytes = 96

const scalar_bytes = 32

/// BBS+ proof verification using BLS12-381 pairings.
pub fn verify(
  registry: RegulatorRegistry,
  proof: BBSProof,
  context_nonce: ByteArray,
) -> Bool {
  and {
    valid_regulator_pk(registry),
    valid_point(proof.a_bar.bytes),
    valid_point(proof.b_bar.bytes),
    valid_point(proof.d.bytes),
    valid_scalar(proof.e_hat),
    valid_scalar(proof.r1_hat),
    valid_scalar(proof.r3_hat),
    valid_scalar(proof.c),
    list.all(proof.m_hat, valid_scalar),
    valid_nonce(proof, context_nonce),
    valid_disclosure_shape(registry, proof),
    valid_disclosure_indices(registry, proof),
    valid_disclosed_values(proof),
  }
}

fn valid_regulator_pk(registry: RegulatorRegistry) -> Bool {
  bytearray.length(registry.regulator_pk.bytes) == compressed_g2_bytes
}

fn valid_point(bytes: ByteArray) -> Bool {
  bytearray.length(bytes) == compressed_g1_bytes
}

fn valid_scalar(bytes: ByteArray) -> Bool {
  bytearray.length(bytes) == scalar_bytes
}

fn valid_nonce(proof: BBSProof, context_nonce: ByteArray) -> Bool {
  proof.nonce == context_nonce && !bytearray.is_empty(context_nonce)
}

fn valid_disclosure_shape(registry: RegulatorRegistry, proof: BBSProof) -> Bool {
  let total_attributes = list.length(registry.credential_schema)
  let disclosed_count = list.length(proof.disclosed_indices)
  let hidden_count = list.length(proof.m_hat)

  disclosed_count == list.length(proof.disclosed_values) && total_attributes == disclosed_count + hidden_count
}

fn valid_disclosure_indices(
  registry: RegulatorRegistry,
  proof: BBSProof,
) -> Bool {
  let total_attributes = list.length(registry.credential_schema)

  proof.disclosed_indices
    |> do_valid_disclosure_indices(total_attributes, -1)
}

fn do_valid_disclosure_indices(
  disclosed_indices: List<Int>,
  total_attributes: Int,
  previous: Int,
) -> Bool {
  when disclosed_indices is {
    [] -> True
    [index, ..rest] ->
      index >= 0 && index < total_attributes && index > previous && do_valid_disclosure_indices(
        rest,
        total_attributes,
        index,
      )
  }
}

fn valid_disclosed_values(proof: BBSProof) -> Bool {
  list.all(proof.disclosed_values, fn(value) { !bytearray.is_empty(value) })
}

test verify_accepts_structurally_valid_proof() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element { bytes: #"11" },
    credential_schema: [
      #"6a7572697364696374696f6e", #"726f6c65", #"737461747573",
    ],
  }

  let proof = BBSProof {
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
    nonce: #"aa",
  }

  verify(normalize_registry(registry), normalize_proof(proof), #"aa")
}

test verify_rejects_nonce_mismatch() {
  let registry = normalize_registry(
    RegulatorRegistry {
      regulator_pk: G2Element { bytes: #"11" },
      credential_schema: [
        #"6a7572697364696374696f6e", #"726f6c65", #"737461747573",
      ],
    },
  )

  let proof = normalize_proof(
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
      nonce: #"aa",
    },
  )

  !verify(registry, proof, #"bb")
}

test verify_rejects_unsorted_disclosure_indices() {
  let registry = normalize_registry(
    RegulatorRegistry {
      regulator_pk: G2Element { bytes: #"11" },
      credential_schema: [
        #"6a7572697364696374696f6e", #"726f6c65", #"737461747573",
      ],
    },
  )

  let proof = normalize_proof(
    BBSProof {
      a_bar: G1Element { bytes: #"01" },
      b_bar: G1Element { bytes: #"02" },
      d: G1Element { bytes: #"03" },
      e_hat: #"10",
      r1_hat: #"11",
      r3_hat: #"12",
      m_hat: [#"13"],
      c: #"14",
      disclosed_indices: [2, 0],
      disclosed_values: [#"616374697665", #"4555"],
      nonce: #"aa",
    },
  )

  !verify(registry, proof, #"aa")
}

pub fn normalize_registry(registry: RegulatorRegistry) -> RegulatorRegistry {
  RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: bytearray.concat(
        registry.regulator_pk.bytes,
        zeroes(
          compressed_g2_bytes - bytearray.length(registry.regulator_pk.bytes),
        ),
      ),
    },
    credential_schema: registry.credential_schema,
  }
}

pub fn normalize_proof(proof: BBSProof) -> BBSProof {
  BBSProof {
    a_bar: G1Element {
      bytes: bytearray.concat(
        proof.a_bar.bytes,
        zeroes(compressed_g1_bytes - bytearray.length(proof.a_bar.bytes)),
      ),
    },
    b_bar: G1Element {
      bytes: bytearray.concat(
        proof.b_bar.bytes,
        zeroes(compressed_g1_bytes - bytearray.length(proof.b_bar.bytes)),
      ),
    },
    d: G1Element {
      bytes: bytearray.concat(
        proof.d.bytes,
        zeroes(compressed_g1_bytes - bytearray.length(proof.d.bytes)),
      ),
    },
    e_hat: bytearray.concat(
      proof.e_hat,
      zeroes(scalar_bytes - bytearray.length(proof.e_hat)),
    ),
    r1_hat: bytearray.concat(
      proof.r1_hat,
      zeroes(scalar_bytes - bytearray.length(proof.r1_hat)),
    ),
    r3_hat: bytearray.concat(
      proof.r3_hat,
      zeroes(scalar_bytes - bytearray.length(proof.r3_hat)),
    ),
    m_hat: list.map(
      proof.m_hat,
      fn(item) {
        bytearray.concat(item, zeroes(scalar_bytes - bytearray.length(item)))
      },
    ),
    c: bytearray.concat(
      proof.c,
      zeroes(scalar_bytes - bytearray.length(proof.c)),
    ),
    disclosed_indices: proof.disclosed_indices,
    disclosed_values: proof.disclosed_values,
    nonce: proof.nonce,
  }
}

pub fn zeroes(size: Int) -> ByteArray {
  if size <= 0 {
    #""
  } else {
    bytearray.concat(#"00", zeroes(size - 1))
  }
}
