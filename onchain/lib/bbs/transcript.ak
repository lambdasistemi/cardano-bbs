use aiken/collection/list
use aiken/crypto/bls12_381/scalar
use aiken/primitive/bytearray
use bbs/generators
use bbs/types.{G1Element, G2Element}

const api_id = "BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_"

const h2s_dst = "BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_H2S_"

const map_msg_scalar_dst =
  "BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_MAP_MSG_TO_SCALAR_AS_HASH_"

const scalar_expand_len = 48

pub fn hash_to_scalar(msg_octets: ByteArray, dst: ByteArray) -> ByteArray {
  generators.expand_message_xmd(msg_octets, dst, scalar_expand_len)
    |> scalar.from_bytes
    |> scalar.to_bytes
}

pub fn map_message_to_scalar_as_hash(message: ByteArray) -> ByteArray {
  hash_to_scalar(message, map_msg_scalar_dst)
}

pub fn calculate_domain(
  regulator_pk: G2Element,
  header: ByteArray,
  message_count: Int,
) -> ByteArray {
  let generator_points = generators.create_generators(message_count + 1)
  let q_1 = expect_some(list.at(generator_points, 0))
  let h_points = list.drop(generator_points, 1)

  let dom_input = bytearray.concat(
    regulator_pk.bytes,
    bytearray.concat(
      domain_octets(q_1, h_points),
      bytearray.concat(i2osp(bytearray.length(header), 8), header),
    ),
  )

  hash_to_scalar(dom_input, h2s_dst)
}

pub fn calculate_challenge(
  disclosed_indexes: List<Int>,
  disclosed_scalars: List<ByteArray>,
  a_bar: G1Element,
  b_bar: G1Element,
  d: G1Element,
  t_1: G1Element,
  t_2: G1Element,
  domain: ByteArray,
  presentation_header: ByteArray,
) -> ByteArray {
  let disclosed_count = list.length(disclosed_indexes)

  let c_arr = bytearray.concat(
    i2osp(disclosed_count, 8),
    bytearray.concat(
      encode_disclosed_pairs(disclosed_indexes, disclosed_scalars),
      bytearray.concat(
        a_bar.bytes,
        bytearray.concat(
          b_bar.bytes,
          bytearray.concat(
            d.bytes,
            bytearray.concat(
              t_1.bytes,
              bytearray.concat(
                t_2.bytes,
                bytearray.concat(
                  domain,
                  bytearray.concat(
                    i2osp(bytearray.length(presentation_header), 8),
                    presentation_header,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  )

  hash_to_scalar(c_arr, h2s_dst)
}

fn domain_octets(q_1: G1Element, h_points: List<G1Element>) -> ByteArray {
  let message_count = list.length(h_points)

  bytearray.concat(
    i2osp(message_count, 8),
    bytearray.concat(
      q_1.bytes,
      bytearray.concat(encode_points(h_points), api_id),
    ),
  )
}

fn encode_points(points: List<G1Element>) -> ByteArray {
  when points is {
    [] -> #""
    [point, ..rest] -> bytearray.concat(point.bytes, encode_points(rest))
  }
}

fn encode_disclosed_pairs(
  disclosed_indexes: List<Int>,
  disclosed_scalars: List<ByteArray>,
) -> ByteArray {
  when disclosed_indexes is {
    [] -> #""
    [index, ..rest_indexes] ->
      when disclosed_scalars is {
        [] -> #""
        [message, ..rest_messages] ->
          bytearray.concat(
            i2osp(index, 8),
            bytearray.concat(
              message,
              encode_disclosed_pairs(rest_indexes, rest_messages),
            ),
          )
      }
  }
}

fn expect_some(value: Option<G1Element>) -> G1Element {
  when value is {
    Some(point) -> point
    None -> G1Element { bytes: #"" }
  }
}

fn i2osp(value: Int, size: Int) -> ByteArray {
  bytearray.from_int_big_endian(value, size)
}

test hash_to_scalar_matches_sha_256_fixture() {
  hash_to_scalar(
    #"9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
    h2s_dst,
  ) == #"0f90cbee27beb214e6545becb8404640d3612da5d6758dffeccd77ed7169807c"
}

test map_message_to_scalar_matches_fixture_cases() {
  and {
    map_message_to_scalar_as_hash(
      #"9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
    ) == #"1cb5bb86114b34dc438a911617655a1db595abafac92f47c5001799cf624b430",
    map_message_to_scalar_as_hash(#"") == #"08e3afeb2b4f2b5f907924ef42856616e6f2d5f1fb373736db1cca32707a7d16",
  }
}

test calculate_domain_matches_proof_fixture() {
  calculate_domain(
    G2Element {
      bytes: #"a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c",
    },
    #"11223344556677889900aabbccddeeff",
    10,
  ) == #"6272832582a0ac96e6fe53e879422f24c51680b25fbf17bad22a35ea93ce5b47"
}

test calculate_challenge_matches_proof_fixture() {
  let disclosed_messages = [
    #"9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
    #"7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73",
    #"496694774c5604ab1b2544eababcf0f53278ff50", #"d183ddc6e2665aa4e2f088af",
  ]

  let disclosed_scalars = list.map(
    disclosed_messages,
    map_message_to_scalar_as_hash,
  )

  calculate_challenge(
    [0, 2, 4, 6],
    disclosed_scalars,
    G1Element {
      bytes: #"a2ed608e8e12ed21abc2bf154e462d744a367c7f1f969bdbf784a2a134c7db2d340394223a5397a3011b1c340ebc4151",
    },
    G1Element {
      bytes: #"99462ba6f31106d8a6da8b513b37a47afe93c9b3474d0d7a354b2edc1b88818b063332df774c141f7a07c48fe50d452f",
    },
    G1Element {
      bytes: #"897739228c88afc797916dca01e8f03bd9c5375c7a7c59996e514bb952a436afd24457658acbaba5ddac2e693ac48135",
    },
    G1Element {
      bytes: #"84719c2b5bb275ee74913dbf95fb9054f690c8e4035f1259e184e9024544bc4bbea9c244e7897f9db7c82b7b14b27d28",
    },
    G1Element {
      bytes: #"8f5f191c956aefd5c960e57d2dfbab6761eb0ebc5efdba1aca1403dcc19e05296b16c9feb7636cb4ef2a360c5a148483",
    },
    #"6272832582a0ac96e6fe53e879422f24c51680b25fbf17bad22a35ea93ce5b47",
    #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  ) == #"341bdaa4b1a37f8c06348f38a4f80c5a2650a21d59f09e8305dcd3fc3ac30e2a"
}
