use bbs/types.{BBSProof, G1Element, G2Element, RegulatorRegistry}
use bbs/verify

test verify_budget_case_total_1_disclosed_1() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"ab0fcd354bb105c21f74618c582c1826c5963d019b70e5da2d965496a13e8701928759e80f3890284df74cff323eba3410fb180d14c8fdf2c2988e6358bec3fb5d286ceb7560b32a0a947593f07167578d086cc839ffbd4ee625068f22d04db3",
    },
    credential_schema: [#"6d"],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"8d0aed8a48a959c7c9e29acca90e17279d59f5f503d922c2b8dc3cd896133ae6a3ea6ba8f97d421833d1bf2f8b81310d",
    },
    b_bar: G1Element {
      bytes: #"a0fc951d8b3b296c9be9084af64fe1c3f06bb2f065a36764633128f481a5e4aa04c2ddd4f8dbaaa0a25be10397983093",
    },
    d: G1Element {
      bytes: #"a36ea7b78791926cd21dd67b686ba4307e5b07487a83ef3252566cf07491b592ccb875f9324488c3e480f081adcab0d1",
    },
    e_hat: #"6bde444c0d84791285742cfcde9358f4f4bfb1cd3370a7ff9aab57b6b8892787",
    r1_hat: #"6306d31ebfec72a0709c56d5c399a953c29b8b19885de7136b34dcbd6b897758",
    r3_hat: #"51ddc36abaf141ba1f9f346878b81d2a590521c3024b3b0921265488b1c6bdea",
    m_hat: [],
    c: #"5bc61a88ca132eff51d0e32eb80ea1cc660984a182d1c7eca2a6b827541949c3",
    disclosed_indices: [0],
    disclosed_values: [#"6d73672d30"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_budget_case_total_5_disclosed_1() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"80b5469d6f31ecd8ea4aeb1a6663313487ea719171c4a253299a760bdb34b92a07cc23287ca329ba9ce0f200cec2669a116b14773fc3720ab6ceaab6a1ecb65218d0ef1718a30ca89ec49cc4008419f66e42af50e846487b01b5d85d9ac6bef4",
    },
    credential_schema: [#"6d", #"6d", #"6d", #"6d", #"6d"],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"a8bc9099909a0d9bda28ffaabb13dec24056f34b67925439fcf4148512dfce1953f94f84bc67e3c040f7cbd9fc08c2eb",
    },
    b_bar: G1Element {
      bytes: #"981ac1d300d73965eaf3525ed1140f36f58a952dc8c756594a693eb341e25d1256faa899fb89880d752b474405cf72b4",
    },
    d: G1Element {
      bytes: #"8580a682e78dcf4c4cd653b52daa013c84d7aad4d2431ffc08392697e68fa99bd48f14db9f9076b52190c06a2fc975bf",
    },
    e_hat: #"465dd04638dbaff317f3005ad938e722d37717e0fd956b7343f5058388c2c683",
    r1_hat: #"51fd52cee67fb194e4fc4ff9201710ecd2e4bcd2f255023fa17de85b61fe00a2",
    r3_hat: #"0505ec2ac53d53c2ba0b098721a23474c2db6c860b4b2e0e158aef0a863c7fc1",
    m_hat: [
      #"07ac1cb9d9d1656dbfb07dd61d3894f1f93ec153afe592a589eea0785f419053",
      #"38cdaac24d8c91446be5db4272441e26a0a3dc07503818a87c70b8910501704d",
      #"7249c02fe6e60a1c0550773d0c596c52c819b33cb10492e6b3c9fa03a122c742",
      #"31c2d140fce0ab300b56f881d89dd2c5dfc2af159b53d2914523e651f1638542",
    ],
    c: #"3827c5884279fea6d6c11e1586594de17c0a9a0b9eef8a80d615041f9486ffaa",
    disclosed_indices: [0],
    disclosed_values: [#"6d73672d30"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_budget_case_total_5_disclosed_2() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"98cc1851341dc52e93fa18f3f6ac786db3f825228c43a80f64298f089dd9f744c893af81dd4682aec10b89583c5ef04417792e7a227fe57f1321c35fe0e39d946198f5bedb732dc3a73b3cf7735d533ba2a8ebcd44f4b134c750db8e22100dd9",
    },
    credential_schema: [#"6d", #"6d", #"6d", #"6d", #"6d"],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"a7b0165cb59f702158656bd1d014973e1ebdfdafa0b5461a0549bbc3c06a700c180c5ed417e92b75d1950fa625134321",
    },
    b_bar: G1Element {
      bytes: #"a72dbc87fc0c2be477e148f021485bced2f384865895a39c4050d65b9fd9125e8fa909a8be028cc99f07a2af3a7506a8",
    },
    d: G1Element {
      bytes: #"b705fdf0be58696d9186aba54c03681045acb49772092f02864486d0275abcaa566eaa501f5b4e3e4c75fc333aed7da0",
    },
    e_hat: #"68ef1ae5f78d96a7d1ae3aaa014178580a6dd28f592ea00fdc178c6409fcddd3",
    r1_hat: #"640d3174a2674deacff48852dec7a02498f754f08fb9c7823ddc8a79c9b07d04",
    r3_hat: #"3b81d5880a253be22f54f6de2f8c9c0dc3eab8495da4bf710a80833c21ae8889",
    m_hat: [
      #"2dfbc7c70fc3345013323f5d31937983f9b9eb5c137dd2b9cd0e4196f2bd5d5b",
      #"0c1592fe15a247fab700ba6e0c944e840401f3c2564df0f2e577ec6d66277069",
      #"447dfceb00492d0b8e6f0b6a038d5138dd4b53e9266486e367062d8cf3386b76",
    ],
    c: #"20fb2816d0b8faa0f514f14786b2531b4234b8fce86f0563f1446e0f9c3604ab",
    disclosed_indices: [0, 2],
    disclosed_values: [#"6d73672d30", #"6d73672d32"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_budget_case_total_10_disclosed_1() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"b790a842b189f47e16c155dcdd0683a0612aa88b03bb4e9cad9649da37e663c91c3f05e224efab0fbcc2d8a0550b2d0101376d061649e9c0c4a931a51f281a95339949570faa6c6cca0f9c45b1050436c233328725299f8cd6232dd6d70e1cfd",
    },
    credential_schema: [
      #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d",
    ],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"84b5d1c3312d1ff769afa4f52e0f7fdf6cfc163b8ba6ad93b17530a57dfdd8c4b8d933215fe15b69827c889f13235757",
    },
    b_bar: G1Element {
      bytes: #"b55e41757f8f7e5fd704d4031a0293c1e4bc2c7b11b770e4329dde4c44c0e18cae37366c5e03febd8578376ba95aaa05",
    },
    d: G1Element {
      bytes: #"a53349b8b0f19e72ac97b7d4e6efe5d4489c6f2e6a27295d8b2b6050f2a190440937bcc44e23ccc6ee889032edbff65d",
    },
    e_hat: #"376c7cd2052db0764f211d0fa39e26a4fbc632032c028d53a5a8c1f08760740c",
    r1_hat: #"4bfa54a633bbc18390934e5c9ea31656a0c3075e59a15a60f27fe92abc272b51",
    r3_hat: #"70ed5e3e7dcb61930a523b9b47c43b3255fd639a8d5bf8e704925557917925e9",
    m_hat: [
      #"350571db8dc2a1dde2d0c10d5a26dab51f8b532509eedba5cc2a6f9636b6fe89",
      #"2a5f48aabe80a0c9edeb98347d630939d0e06df80286856df5f1107958a9ccb3",
      #"677967cf4579f32a3d88b68eb0cb93183ead122a93de7014bdfe8fbc0a676c6d",
      #"0760f6a5bc9ed7b994f9928014eac7dff609e10d3493df35c62e6d1cfd855cb5",
      #"2ef6a5f72daf6048dd9345d59040c4e747f09f4ace5ab7de30ed19f1300d2f60",
      #"4bf458d7194df65b49bcc7b09679e173eb051a38a9b657ea4c464622d0505f58",
      #"028fe314d60fbdb164ae6b935e6c3ce60f4680b4a1296794523b9b179e665ef0",
      #"21ac14a48d884f69c3fbf54531e5e7cffda8aa90e1cdff4ea85dbde9975f711c",
      #"1058a8dd282e95db11e8f2d11c1ba4f7a42c7a423c36cf482477ed1c691a17ac",
    ],
    c: #"48bc501f744e64474fe50c61ff0421efbcaa6d523fb9d403a0f20ee6eeb3a831",
    disclosed_indices: [0],
    disclosed_values: [#"6d73672d30"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_budget_case_total_10_disclosed_2() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"a0e4f3206af75ddd72700c4ffec35866063216c97efe9258c88bbdf11b596f91a1a0611f83cfc11a13f2c47aed110e6716673b2f6b94ed5a5a45ca03d6faa69b40094065edd5838325ce0f1025e89364236788a39f2ffb14a4dcccb45fe480ec",
    },
    credential_schema: [
      #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d",
    ],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"801f5ff95932188031f609315d26c93648529543b932d48eb879c8bb6f4e85fdb0fd49c4d9e4a7563d4a0b0755b1c2dd",
    },
    b_bar: G1Element {
      bytes: #"83b9e0a29f4574e09397e7778866b43ec50242d23e5c31091e9a42639c1d63ac3c84bd89b643770716816156e91f3535",
    },
    d: G1Element {
      bytes: #"8792b13dbd8f0b142dd2c5b2a9d3e2c3f88b4af813be410995bc4e03088c001e28638e03c37b4f67c9075da4938d16a5",
    },
    e_hat: #"51ef002c75a176425361d792295edb6bc46eeee76854aaa5b3e28f5a0e75333d",
    r1_hat: #"599048269bdbeccadddce7d3ee984dc80d055b4e68f6ff79aa2eab9ddf7b1f89",
    r3_hat: #"3e908ab5cd0c7bcd96e34d0d0c5ca5c85b5f95aa513407dc56109f46c159f2c7",
    m_hat: [
      #"0475241356217f480c0c3f1bcbda856de8541cd2a37bc3d2b38fad43ac8d8f9b",
      #"360df4037da74fa58c8ad3d4e05803c5ff867bf3867671d519837ccf70f62c38",
      #"55838e1cefc2c4283004d34281f1a63b6341010d0db59e8cb6c8c6a95b45dbb3",
      #"124f0be7123b38aebb0a71460e20e8a8605e64c1ab5d7b858d955cbfbf98be92",
      #"48797c36119d4306bf5c05d2e1c7204cefa7cc4bea9391eb4525ab2b727161fe",
      #"6d24c9406ddff5d4037e942cb499d1ab28effbdaacc2c626d264d4bf3c9d427a",
      #"59e15b827e5fc8e475acf383de9f4f3591cb4ac3034273656b888c4c3bccae81",
      #"700d2139ab8e3b15d640bc87ac6ddd5173710f332f7c16fd8ba30af861e716dc",
    ],
    c: #"46302b911d74ca6814eb582c9b72f1f7a2099701c4e6e6bbe7e2e12cad5e3203",
    disclosed_indices: [0, 2],
    disclosed_values: [#"6d73672d30", #"6d73672d32"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_budget_case_total_15_disclosed_1() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"a5b66e0477bb52669a731db7e6a14b981df8757aeccf3187269b067303ae8313a3d644a3124c21168438b18c11f580d212c40f4728fcda63782d1fb29ea7c0e0e530925efcc615e1cdec328c4d763939e654cf1a32b57dbcf2b2361b07db8cce",
    },
    credential_schema: [
      #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d",
      #"6d", #"6d", #"6d", #"6d", #"6d",
    ],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"a879ec936aaff43c84573ef89f4ea850e3ceda1680830a909c2d22e629727352a9619c62d9eb94d5567da21c27f12322",
    },
    b_bar: G1Element {
      bytes: #"a7dc3e521d1d07f1b365e5c0c57cfa77ceed47d0ed5f7781f844a0d358d2191bdbafc19b5fdebef9cdadd7205f22c087",
    },
    d: G1Element {
      bytes: #"a12fd5d4fc4bfbcf03042ba92ef2f3bfb9ac7b822dcdfad77d72c96d59d1ca3db9f5b481b519345ba92fa760e2c6388d",
    },
    e_hat: #"11bb9f211d95ae81f601df9a630a24ae9d419cbe2de40325ab3f7cd6dcb96db0",
    r1_hat: #"73b09dfd9f71a7c4f35a3d007a943978a870ec409334e93beae4a98f43ea3773",
    r3_hat: #"5592e8581865e79413e1ef089e8ef4749d0d4fa92f14dd56bcbffcdb6ba4ff3f",
    m_hat: [
      #"03c11652d5f92fde6ec6a3011903d6cb1a6a33308b8a742b488759f5cf15ec10",
      #"66b7ddcd0660f5663be32c41ca5dd078cdc972632b525ca59ada93f9625d46fb",
      #"028cb4069f219fad98eebe16ff273caffc7dbf6384d84b7ab35c0c57be1ad7f2",
      #"37b951e6e4973e1b0d45fd1ad79eefc37ecc4f6c270b3cd152a0c4c12371a76a",
      #"2392ec9dc0a4ce117b75aa09a5247e10494dcfc606b2fd6adb1abb5c533ae6d1",
      #"48c167abe80bd796e4d01a383fe2b66a43fe425bf4637702ad160bda8c8607bd",
      #"3dfa26fb00634316f6a92f1ddb80093aa9a6169ce105480bbcb90259e92f1f94",
      #"4f04a1905170ffc4759f2a97aa46af7bc7493b4364c47c42bfb75a68fa6081c3",
      #"006cc6cbc5c079ed13c1e792009cbd8e322445cc7da865d3200451508ddcceaa",
      #"0bbae73938724a0d2c0d8d5e6c5fd3ee6e5f4b6a26485330d3d171ec35c50fb6",
      #"0267ebddf6904b25356fa4f0956d84f0483a6ad9215dbc1b2affbf0b255961bc",
      #"23035c593776b573551ea59d0127307f1d5ca875e2e15bb300cc8eb26c708bb1",
      #"7059d1c789b60377988ce2aa0a33407861084d8b59e186bcfd08a9cdff3fff61",
      #"11f0dfa97422ea4ce1c7cf7d3a3e67fd79c302acc5c7c8ecb8c2c16794b6c719",
    ],
    c: #"32dacbddc894fc27258ed2921b946ed7b28a54b8dc371ca02d5951b9980ebcfb",
    disclosed_indices: [0],
    disclosed_values: [#"6d73672d30"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}

test verify_budget_case_total_15_disclosed_2() {
  let registry = RegulatorRegistry {
    regulator_pk: G2Element {
      bytes: #"b1e0dbc65ceedd122885ed40c39700ab6fc71be09b26813fc7f3c145faa22b83e2b34a4b158653378c382d707fcedb501737a5a313f67e5af113b49e2529fe9f2459f6394f4e430157ddf5611b62ce4334671484d40e5ebbf836e424d411a6f2",
    },
    credential_schema: [
      #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d", #"6d",
      #"6d", #"6d", #"6d", #"6d", #"6d",
    ],
    signed_header: #"",
  }

  let proof = BBSProof {
    a_bar: G1Element {
      bytes: #"ac939d9c82bf630cfb3e00defe368f947edc5f49a5335e4b383dc8cf9b88854bb9a38e408de3aff1644adacb9808b5fd",
    },
    b_bar: G1Element {
      bytes: #"84005d69ba2860ac3f5bb8733bec7c311ab94bc389eba98664bf1eb1fe0b0e5577dcac0f05dbc72309d5bb872c04c8be",
    },
    d: G1Element {
      bytes: #"aba8708e4bc11ab2710d7a28875306f3de12fe19f24d99013991824763b9e512d25a4e96711156c0c113af2577991c00",
    },
    e_hat: #"41ffaa6a22a4a06db2b6226968803fbda31aa17a2066c6eadcd066053b7616f3",
    r1_hat: #"4b9283d7b251db541ab0a3cc2594f45cebcf961af1226454f0df0200ce9b0a64",
    r3_hat: #"6175922b93f05c679c84ad6bbebcd99b0605b3591131ddb4c1d661e28d81eb54",
    m_hat: [
      #"6eeae769bf04f2709fac2afc7a9250454e2f047480048474f6b92a4349ea25c1",
      #"6f24da079b66b5ca884770c316c0c682397d44bb99e5fb0164d0b626bfaaea20",
      #"32cba49abb6916a7265a88c02c2cd5125076bc5dba2e6b5fd429a2defe37f486",
      #"71c4768e8409301e8d70a19760eb50f75cabf3de14a3ef593942f44c2be2c05b",
      #"439d0a24172e20cdde421afadd4ab2d78f0da563187a85656819ea0d30ad8e6c",
      #"567fd91edadf21cca22446034fbc6b2c9934444ca99f39de9ee8b3a292c3b670",
      #"2885942bb197e766c9b4b515b5fd5c69e3968d417dafe82095f971d64b96dd95",
      #"398f008e8f61c1fcab0df44b9e87066d28bacb3f0629708945965f579cdc9b36",
      #"48f88ce6d96ff4055fa293534b202ee1f3b4c44149f3283175bb2b799c6ce9c8",
      #"726a5ad47c0fa4b48c249636d68ec3a495feed1ef5cc45c6d9ae798fb7532ef8",
      #"62f247f1f3bb08330c560d217d4a704bc1c0c511bea908bf0f54fb4aa1be9c98",
      #"4941ae903d6f6b7869867066644d5f51d730cdf4a41fb10cd37f448b72581fb5",
      #"690f8222be4a1552df454598af75e2afe25d4e1cd5ae2aaf70c2a14bacee7206",
    ],
    c: #"2d1632ba6ce8ccc91272964e9c29e80cca92ed916e9fadaa618fbcd3d08023e4",
    disclosed_indices: [0, 2],
    disclosed_values: [#"6d73672d30", #"6d73672d32"],
    nonce: #"6275646765743a70726f6f66",
  }

  verify.verify(registry, proof, #"6275646765743a70726f6f66")
}
