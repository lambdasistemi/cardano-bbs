use aiken/collection/list
use aiken/crypto/bls12_381/g1
use aiken/crypto/bls12_381/g2
use aiken/crypto/bls12_381/pairing
use aiken/crypto/bls12_381/scalar
use aiken/primitive/bytearray
use bbs/generators
use bbs/transcript
use bbs/types as bbs_types

const compressed_g1_bytes = 48

const compressed_g2_bytes = 96

const scalar_bytes = 32

/// BBS+ proof verification using BLS12-381 pairings.
pub fn verify(
  registry: bbs_types.RegulatorRegistry,
  proof: bbs_types.BBSProof,
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
    valid_challenge(registry, proof),
    valid_pairing(registry, proof),
  }
}

fn valid_regulator_pk(registry: bbs_types.RegulatorRegistry) -> Bool {
  bytearray.length(registry.regulator_pk.bytes) == compressed_g2_bytes
}

fn valid_point(bytes: ByteArray) -> Bool {
  bytearray.length(bytes) == compressed_g1_bytes
}

fn valid_scalar(bytes: ByteArray) -> Bool {
  bytearray.length(bytes) == scalar_bytes && scalar.to_bytes(
    scalar.from_bytes(bytes),
  ) == bytes
}

fn valid_nonce(proof: bbs_types.BBSProof, context_nonce: ByteArray) -> Bool {
  proof.nonce == context_nonce && !bytearray.is_empty(context_nonce)
}

fn valid_disclosure_shape(
  registry: bbs_types.RegulatorRegistry,
  proof: bbs_types.BBSProof,
) -> Bool {
  let total_attributes = list.length(registry.credential_schema)
  let disclosed_count = list.length(proof.disclosed_indices)
  let hidden_count = list.length(proof.m_hat)

  disclosed_count == list.length(proof.disclosed_values) && total_attributes == disclosed_count + hidden_count
}

fn valid_disclosure_indices(
  registry: bbs_types.RegulatorRegistry,
  proof: bbs_types.BBSProof,
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

fn valid_disclosed_values(proof: bbs_types.BBSProof) -> Bool {
  list.all(proof.disclosed_values, fn(value) { !bytearray.is_empty(value) })
}

fn valid_challenge(
  registry: bbs_types.RegulatorRegistry,
  proof: bbs_types.BBSProof,
) -> Bool {
  let total_attributes = list.length(registry.credential_schema)
  let all_generators = generators.create_generators(total_attributes + 1)
  let disclosed_scalars = list.map(
    proof.disclosed_values,
    transcript.map_message_to_scalar_as_hash,
  )
  let domain = transcript.calculate_domain(
    registry.regulator_pk,
    #"",
    total_attributes,
  )
  let hidden_indices = remaining_indices(
    total_attributes,
    proof.disclosed_indices,
    0,
  )
  let t_1 = compute_t_1(proof)
  let t_2 = compute_t_2(
    proof,
    disclosed_scalars,
    domain,
    hidden_indices,
    all_generators,
  )

  transcript.calculate_challenge(
    proof.disclosed_indices,
    disclosed_scalars,
    proof.a_bar,
    proof.b_bar,
    proof.d,
    t_1,
    t_2,
    domain,
    proof.nonce,
  ) == proof.c
}

fn valid_pairing(
  registry: bbs_types.RegulatorRegistry,
  proof: bbs_types.BBSProof,
) -> Bool {
  pairing.final_exponentiation(
    pairing.miller_loop(
      g1.decompress(proof.a_bar.bytes),
      g2.decompress(registry.regulator_pk.bytes),
    ),
    pairing.miller_loop(g1.decompress(proof.b_bar.bytes), g2.generator),
  )
}

fn compute_t_1(proof: bbs_types.BBSProof) -> bbs_types.G1Element {
  compress_point(
    add_native_points(
      add_native_points(
        scale_native_point(decompress_point(proof.b_bar), proof.c),
        scale_native_point(decompress_point(proof.a_bar), proof.e_hat),
      ),
      scale_native_point(decompress_point(proof.d), proof.r1_hat),
    ),
  )
}

fn compute_t_2(
  proof: bbs_types.BBSProof,
  disclosed_scalars: List<ByteArray>,
  domain: ByteArray,
  hidden_indices: List<Int>,
  all_generators: List<bbs_types.G1Element>,
) -> bbs_types.G1Element {
  let b_v = compute_b_v(
    proof.disclosed_indices,
    disclosed_scalars,
    domain,
    all_generators,
  )
  let initial = add_native_points(
    scale_native_point(b_v, proof.c),
    scale_native_point(decompress_point(proof.d), proof.r3_hat),
  )

  compress_point(
    add_hidden_terms(hidden_indices, proof.m_hat, initial, all_generators),
  )
}

fn compute_b_v(
  disclosed_indices: List<Int>,
  disclosed_scalars: List<ByteArray>,
  domain: ByteArray,
  all_generators: List<bbs_types.G1Element>,
) -> G1Element {
  let initial = add_native_points(
    decompress_point(generators.p_1()),
    scale_native_point(
      decompress_point(expect_generator(all_generators, 0)),
      domain,
    ),
  )

  add_disclosed_terms(
    disclosed_indices,
    disclosed_scalars,
    initial,
    all_generators,
  )
}

fn add_disclosed_terms(
  disclosed_indices: List<Int>,
  disclosed_scalars: List<ByteArray>,
  acc: G1Element,
  all_generators: List<bbs_types.G1Element>,
) -> G1Element {
  when disclosed_indices is {
    [] -> acc
    [index, ..rest_indexes] ->
      when disclosed_scalars is {
        [] -> acc
        [message, ..rest_messages] ->
          add_disclosed_terms(
            rest_indexes,
            rest_messages,
            add_native_points(
              acc,
              scale_native_point(
                decompress_point(expect_generator(all_generators, index + 1)),
                message,
              ),
            ),
            all_generators,
          )
      }
  }
}

fn add_hidden_terms(
  hidden_indices: List<Int>,
  hidden_scalars: List<ByteArray>,
  acc: G1Element,
  all_generators: List<bbs_types.G1Element>,
) -> G1Element {
  when hidden_indices is {
    [] -> acc
    [index, ..rest_indexes] ->
      when hidden_scalars is {
        [] -> acc
        [value, ..rest_values] ->
          add_hidden_terms(
            rest_indexes,
            rest_values,
            add_native_points(
              acc,
              scale_native_point(
                decompress_point(expect_generator(all_generators, index + 1)),
                value,
              ),
            ),
            all_generators,
          )
      }
  }
}

fn remaining_indices(
  total_attributes: Int,
  disclosed_indices: List<Int>,
  current: Int,
) -> List<Int> {
  if current >= total_attributes {
    []
  } else {
    if contains_index(disclosed_indices, current) {
      remaining_indices(total_attributes, disclosed_indices, current + 1)
    } else {
      [
        current,
        ..remaining_indices(total_attributes, disclosed_indices, current + 1)
      ]
    }
  }
}

fn contains_index(indices: List<Int>, target: Int) -> Bool {
  when indices is {
    [] -> False
    [index, ..rest] -> index == target || contains_index(rest, target)
  }
}

fn expect_generator(
  all_generators: List<bbs_types.G1Element>,
  index: Int,
) -> bbs_types.G1Element {
  when list.at(all_generators, index) is {
    Some(point) -> point
    None -> bbs_types.G1Element { bytes: #"" }
  }
}

fn decompress_point(point: bbs_types.G1Element) -> G1Element {
  g1.decompress(point.bytes)
}

fn compress_point(point: G1Element) -> bbs_types.G1Element {
  bbs_types.G1Element { bytes: g1.compress(point) }
}

fn add_native_points(left: G1Element, right: G1Element) -> G1Element {
  g1.add(left, right)
}

fn scale_native_point(point: G1Element, factor: ByteArray) -> G1Element {
  g1.scale(point, scalar.from_bytes(factor))
}

test verify_accepts_structurally_valid_proof() {
  let registry = bbs_types.RegulatorRegistry {
    regulator_pk: bbs_types.G2Element {
      bytes: #"a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c",
    },
    credential_schema: [
      #"6d30", #"6d31", #"6d32", #"6d33", #"6d34", #"6d35", #"6d36", #"6d37",
      #"6d38", #"6d39",
    ],
  }

  let proof = bbs_types.BBSProof {
    a_bar: bbs_types.G1Element {
      bytes: #"81925c2e525d9fbb0ba95b438b5a13fff5874c7c0515c193628d7d143ddc3bb487771ad73658895997a88dd5b254ed29",
    },
    b_bar: bbs_types.G1Element {
      bytes: #"abc019bfca62c09b8dafb37e5f09b1d380e084ec3623d071ec38d6b8602af93aa0ddbada307c9309cca86be16db53dc7",
    },
    d: bbs_types.G1Element {
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

  verify(
    registry,
    proof,
    #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  )
}

test verify_rejects_nonce_mismatch() {
  let registry = bbs_types.RegulatorRegistry {
    regulator_pk: bbs_types.G2Element {
      bytes: #"a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c",
    },
    credential_schema: [
      #"6d30", #"6d31", #"6d32", #"6d33", #"6d34", #"6d35", #"6d36", #"6d37",
      #"6d38", #"6d39",
    ],
  }

  let proof = bbs_types.BBSProof {
    a_bar: bbs_types.G1Element {
      bytes: #"81925c2e525d9fbb0ba95b438b5a13fff5874c7c0515c193628d7d143ddc3bb487771ad73658895997a88dd5b254ed29",
    },
    b_bar: bbs_types.G1Element {
      bytes: #"abc019bfca62c09b8dafb37e5f09b1d380e084ec3623d071ec38d6b8602af93aa0ddbada307c9309cca86be16db53dc7",
    },
    d: bbs_types.G1Element {
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

  !verify(
    registry,
    proof,
    #"001122d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  )
}

test verify_rejects_unsorted_disclosure_indices() {
  let registry = normalize_registry(
    bbs_types.RegulatorRegistry {
      regulator_pk: bbs_types.G2Element { bytes: #"11" },
      credential_schema: [
        #"6a7572697364696374696f6e", #"726f6c65", #"737461747573",
      ],
    },
  )

  let proof = normalize_proof(
    bbs_types.BBSProof {
      a_bar: bbs_types.G1Element { bytes: #"01" },
      b_bar: bbs_types.G1Element { bytes: #"02" },
      d: bbs_types.G1Element { bytes: #"03" },
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

test verify_rejects_challenge_mismatch() {
  let registry = bbs_types.RegulatorRegistry {
    regulator_pk: bbs_types.G2Element {
      bytes: #"a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c",
    },
    credential_schema: [
      #"6d30", #"6d31", #"6d32", #"6d33", #"6d34", #"6d35", #"6d36", #"6d37",
      #"6d38", #"6d39",
    ],
  }

  let proof = bbs_types.BBSProof {
    a_bar: bbs_types.G1Element {
      bytes: #"81925c2e525d9fbb0ba95b438b5a13fff5874c7c0515c193628d7d143ddc3bb487771ad73658895997a88dd5b254ed29",
    },
    b_bar: bbs_types.G1Element {
      bytes: #"abc019bfca62c09b8dafb37e5f09b1d380e084ec3623d071ec38d6b8602af93aa0ddbada307c9309cca86be16db53dc7",
    },
    d: bbs_types.G1Element {
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
    c: #"4b70506add5b2eb0be9ff66e3ea8deae666f198edfbb1391c6834e6df4f1026d",
    disclosed_indices: [0, 2, 4, 6],
    disclosed_values: [
      #"9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
      #"7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73",
      #"496694774c5604ab1b2544eababcf0f53278ff50", #"d183ddc6e2665aa4e2f088af",
    ],
    nonce: #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  }

  !verify(
    registry,
    proof,
    #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  )
}

pub fn normalize_registry(
  registry: bbs_types.RegulatorRegistry,
) -> bbs_types.RegulatorRegistry {
  bbs_types.RegulatorRegistry {
    regulator_pk: bbs_types.G2Element {
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

pub fn normalize_proof(proof: bbs_types.BBSProof) -> bbs_types.BBSProof {
  bbs_types.BBSProof {
    a_bar: bbs_types.G1Element {
      bytes: bytearray.concat(
        proof.a_bar.bytes,
        zeroes(compressed_g1_bytes - bytearray.length(proof.a_bar.bytes)),
      ),
    },
    b_bar: bbs_types.G1Element {
      bytes: bytearray.concat(
        proof.b_bar.bytes,
        zeroes(compressed_g1_bytes - bytearray.length(proof.b_bar.bytes)),
      ),
    },
    d: bbs_types.G1Element {
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
