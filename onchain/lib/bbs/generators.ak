use aiken/collection/list
use aiken/crypto
use aiken/crypto/bls12_381/g1
use aiken/primitive/bytearray
use bbs/types.{G1Element}

const api_id = "BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_"

const generator_seed = "MESSAGE_GENERATOR_SEED"

const generator_seed_dst = "SIG_GENERATOR_SEED_"

const generator_dst = "SIG_GENERATOR_DST_"

const sha256_block_bytes = 64

const sha256_output_bytes = 32

const expand_len = 48

pub fn q_1() -> G1Element {
  expect_some(list.at(create_generators(1), 0))
}

pub fn message_generator(index: Int) -> Option<G1Element> {
  if index < 0 {
    None
  } else {
    list.at(create_generators(index + 2), index + 1)
  }
}

pub fn create_generators(count: Int) -> List<G1Element> {
  if count <= 0 {
    []
  } else {
    let seed_dst = bytearray.concat(api_id, generator_seed_dst)
    let point_dst = bytearray.concat(api_id, generator_dst)
    let seed_material = bytearray.concat(api_id, generator_seed)
    let initial_v = expand_message_xmd(seed_material, seed_dst, expand_len)

    derive_generators(1, count, initial_v, seed_dst, point_dst, [])
      |> list.reverse
  }
}

fn derive_generators(
  index: Int,
  count: Int,
  v: ByteArray,
  seed_dst: ByteArray,
  point_dst: ByteArray,
  acc: List<G1Element>,
) -> List<G1Element> {
  if index > count {
    acc
  } else {
    let next_v = expand_message_xmd(
      bytearray.concat(v, i2osp(index, 8)),
      seed_dst,
      expand_len,
    )

    let generator = G1Element {
      bytes: g1.compress(g1.hash_to_group(next_v, point_dst)),
    }

    derive_generators(
      index + 1,
      count,
      next_v,
      seed_dst,
      point_dst,
      [generator, ..acc],
    )
  }
}

pub fn expand_message_xmd(
  msg: ByteArray,
  dst: ByteArray,
  len_in_bytes: Int,
) -> ByteArray {
  let dst_prime = bytearray.concat(dst, i2osp(bytearray.length(dst), 1))
  let z_pad = zeroes(sha256_block_bytes)
  let len_bytes = i2osp(len_in_bytes, 2)
  let ell = ( len_in_bytes + sha256_output_bytes - 1 ) / sha256_output_bytes

  let b_0 = crypto.sha2_256(
    bytearray.concat(
      bytearray.concat(
        bytearray.concat(
          bytearray.concat(bytearray.concat(z_pad, msg), len_bytes),
          #"00",
        ),
        dst_prime,
      ),
      #"",
    ),
  )

  let b_1 = crypto.sha2_256(
    bytearray.concat(bytearray.concat(b_0, #"01"), dst_prime),
  )

  bytearray.take(expand_blocks(2, ell, b_0, b_1, b_1, dst_prime), len_in_bytes)
}

fn expand_blocks(
  index: Int,
  ell: Int,
  b_0: ByteArray,
  previous: ByteArray,
  acc: ByteArray,
  dst_prime: ByteArray,
) -> ByteArray {
  if index > ell {
    acc
  } else {
    let block = crypto.sha2_256(
      bytearray.concat(
        bytearray.concat(
          bytearray.xor_bytes(b_0, previous, False),
          i2osp(index, 1),
        ),
        dst_prime,
      ),
    )

    expand_blocks(
      index + 1,
      ell,
      b_0,
      block,
      bytearray.concat(acc, block),
      dst_prime,
    )
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

fn zeroes(size: Int) -> ByteArray {
  if size <= 0 {
    #""
  } else {
    bytearray.concat(#"00", zeroes(size - 1))
  }
}

test q_1_matches_sha_256_suite_vector() {
  q_1().bytes == #"a9ec65b70a7fbe40c874c9eb041c2cb0a7af36ccec1bea48fa2ba4c2eb67ef7f9ecb17ed27d38d27cdeddff44c8137be"
}

test message_generator_returns_h_1_and_h_10() {
  and {
    message_generator(0) == Some(
      G1Element {
        bytes: #"98cd5313283aaf5db1b3ba8611fe6070d19e605de4078c38df36019fbaad0bd28dd090fd24ed27f7f4d22d5ff5dea7d4",
      },
    ),
    message_generator(9) == Some(
      G1Element {
        bytes: #"a1f229540474f4d6f1134761b92b788128c7ac8dc9b0c52d59493132679673032ac7db3fb3d79b46b13c1c41ee495bca",
      },
    ),
  }
}

test create_generators_matches_fixture_prefix() {
  let generators = create_generators(11)

  and {
    list.length(generators) == 11,
    list.at(generators, 0) == Some(
      G1Element {
        bytes: #"a9ec65b70a7fbe40c874c9eb041c2cb0a7af36ccec1bea48fa2ba4c2eb67ef7f9ecb17ed27d38d27cdeddff44c8137be",
      },
    ),
    list.at(generators, 10) == Some(
      G1Element {
        bytes: #"a1f229540474f4d6f1134761b92b788128c7ac8dc9b0c52d59493132679673032ac7db3fb3d79b46b13c1c41ee495bca",
      },
    ),
  }
}
