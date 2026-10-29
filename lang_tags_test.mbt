///|
test "iso639_1 and bcp47" {
  assert_eq(@mbglot.Eng.iso639_1(), Some("en"))
  assert_eq(@mbglot.Cmn.iso639_1(), Some("zh"))
  assert_eq(@mbglot.Arb.bcp47(), "ar")
  assert_eq(@mbglot.Ceb.iso639_1(), None)
  assert_eq(@mbglot.Ceb.bcp47(), "ceb")
  assert_eq(@mbglot.Ckb.bcp47(), "ckb")
  assert_eq(@mbglot.Kin.bcp47(), "rw")
}

///|
test "two-letter codes are distinct" {
  let seen : Set[String] = Set([])
  for lang in @mbglot.Lang::all() {
    if lang.iso639_1() is Some(code) {
      assert_eq(code.length(), 2)
      assert_false(seen.contains(code))
      seen.add(code)
    }
  }
  assert_eq(seen.length(), 62)
}

///|
test "from_bcp47 round-trips every language" {
  for lang in @mbglot.Lang::all() {
    assert_eq(@mbglot.Lang::from_bcp47(lang.bcp47()), Some(lang))
    assert_eq(@mbglot.Lang::from_bcp47(lang.code()), Some(lang))
    assert_eq(@mbglot.Lang::from_bcp47(lang.bcp47().to_upper()), Some(lang))
  }
}

///|
test "from_bcp47 ignores script, region and other subtags" {
  let cases : Array[(String, @mbglot.Lang?)] = [
    ("pt-BR", Some(Por)),
    ("zh-Hant-TW", Some(Cmn)),
    ("sr-Latn-RS", Some(Srp)),
    ("es_419", Some(Spa)),
    ("en-US-x-private", Some(Eng)),
    ("zh-cmn-Hans", Some(Cmn)),
    ("ar-arb", Some(Arb)),
    ("zh-yue", None),
    ("ar-apc", None),
    ("ger", Some(Deu)),
    ("fil", Some(Tgl)),
    ("in", Some(Ind)),
    ("msa", Some(Zlm)),
    ("ku", None),
    ("ff", None),
    ("nb-NO", None),
    ("", None),
    ("e", None),
    ("engl", None),
    ("e1", None),
    ("-en", None),
  ]
  for case in cases {
    assert_eq((case.0, @mbglot.Lang::from_bcp47(case.0)), case)
  }
}

///|
test "native names" {
  assert_eq(@mbglot.Deu.native_name(), "Deutsch")
  assert_eq(@mbglot.Jpn.native_name(), "日本語")
  for lang in @mbglot.Lang::all() {
    assert_true(lang.native_name() != "")
  }
}
