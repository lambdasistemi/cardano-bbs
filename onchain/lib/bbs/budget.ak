use bbs/types.{BBSProof, G1Element, G2Element, RegulatorRegistry}
use bbs/verify

test verify_accepts_budget_case_single_attribute() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"a0a373679b1d82fd2fc759a4daf3dec73841ac6fd50ce660b9b3d25c175b38429754fe739f59b6ec3be2a1fa5906af6402b999d79f08efb9306f856578f68bb8660b294d2cfd495e1ac118828ec3dd9ed385ec901d80a67c777f8c3eff60ecf0",
    },
    credential_schema: [#"6d"],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"b6329e9f5ea1e591e784d9e7392df000d61af84d150f9382ab5dc3f9bbe71a1bc0b4e2f057aac7d3ec33bb4ce3511dac",
    },
    b_bar: G1Element {
      bytes: #"a3c7ede95d4eef2256b19bfd00171a8575752805841973d5765e50363fea366658dbaa8bee12be581af7ff2c9e99df5d",
    },
    d: G1Element {
      bytes: #"aae3f404b9fa37253e6618c92fefb734bff298fde23b8a630d3f5e859df8e02c0d6d716dda8b0f3a3a4cc5be4fdbf0bd",
    },
    e_hat: #"55711e5f18d48d5a1cfa0425b80bd762cea612cb936cac40cab6bc5b6e06bf72",
    r1_hat: #"26a076e2cca13ab8ba25a7caccca0fb478db151f759fae06a74bd0d6f97d4094",
    r3_hat: #"30a69774d5e3984afcf7c745f44d5b4d8339a9b4ddd745248621ac9fe2b24d36",
    m_hat: [],
    c: #"11cae5fdd7783837aad392837ab551a4f6ace046288d00656c4a14b9e9caaf7d",
    disclosed_indices: [0],
    disclosed_values: [#"6d73672d30"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_accepts_budget_case_five_attributes() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"82edf20881128af08edcc830be8e3811406c1c9daafad12da5854ae7ff544cda0456fd8d67506978533935b2a81eaa06051712ae8c123606266eaae12dc39a678173c7456bf45f54aa4f52b199b4dfb43c1a87637026e8287eef6775becb522f",
    },
    credential_schema: [#"6d", #"6d", #"6d", #"6d", #"6d"],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"8b296f78f5481a5d48cabf135677c1f81c8fac9e10963f922d65a63b3c0d266f355bd1d992246f5492bc4a8bec15402e",
    },
    b_bar: G1Element {
      bytes: #"895d6cd0fda71cf1c5270ce578ae9bd1fd6946c99fdf1f17a481d55fd1e6a7feda6d32dfc3f122a83ac244674af58443",
    },
    d: G1Element {
      bytes: #"82b309152df3c91a6be6e3c1d5b1c8cf4484751f415958214fecfcc3b463976a8e8122076121d784a78be72894efc7c6",
    },
    e_hat: #"63945477efab85969446c6f0ca144dd928b8047e57530a99541dbf544d10b2f6",
    r1_hat: #"2affce60e97127a89198099f6bf95e602baeac49a62f28920cac20497f9bb21a",
    r3_hat: #"0812a64c53609aa7fbbcc974209a7ecb2ee9d43981f20d77be8b7fd98d580a91",
    m_hat: [
      #"550d0c28aafd6bba8ad974349ad94fabda7708aa8eb31b8b78f78848069da8bf",
      #"389188db269ddbe93008bcc2c6f9509e56769f7410c6806a4fbd8e0fcd901a26",
      #"1350ed2fbf073d1f535251e02b5332b734e7e3f456ea3b28bbcb70cae3d1f908",
    ],
    c: #"32aa802a68756e3ecb21fba2d402e17ca68167ae4d053059e0f231cadd8df7f2",
    disclosed_indices: [0, 2],
    disclosed_values: [#"6d73672d30", #"6d73672d32"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_accepts_budget_case_ten_attributes() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c",
    },
    credential_schema: [
      #"6d30", #"6d31", #"6d32", #"6d33", #"6d34", #"6d35", #"6d36", #"6d37",
      #"6d38", #"6d39",
    ],
    signed_header: #"",
  }

  let proof = BBSProof {
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

  verify.verify(
    registry,
    proof,
    #"bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501",
  )
}
