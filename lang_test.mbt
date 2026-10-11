///|
test "all languages have distinct three-letter codes" {
  let langs = @mbglot.Lang::all()
  assert_eq(langs.length(), 76)
  let seen : Set[String] = Set([])
  for lang in langs {
    let code = lang.code()
    assert_eq(code.length(), 3)
    for c in code {
      assert_true(c >= 'a' && c <= 'z')
    }
    assert_false(seen.contains(code))
    seen.add(code)
    assert_true(lang.name() != "")
  }
}

///|
test "from_code round-trips every language" {
  for lang in @mbglot.Lang::all() {
    assert_eq(@mbglot.Lang::from_code(lang.code()), Some(lang))
  }
}

///|
test "from_code ignores ASCII case and rejects unknown codes" {
  assert_eq(@mbglot.Lang::from_code("ENG"), Some(@mbglot.Eng))
  assert_eq(@mbglot.Lang::from_code("Cmn"), Some(@mbglot.Cmn))
  assert_eq(@mbglot.Lang::from_code(""), None)
  assert_eq(@mbglot.Lang::from_code("en"), None)
  assert_eq(@mbglot.Lang::from_code("und"), None)
  assert_eq(@mbglot.Lang::from_code(" eng"), None)
}

///|
test "names" {
  assert_eq(@mbglot.Eng.name(), "English")
  assert_eq(@mbglot.Arb.name(), "Standard Arabic")
  assert_eq(@mbglot.Cmn.code(), "cmn")
}

///|
test "scripts have distinct names" {
  let scripts = @mbglot.Script::all()
  assert_eq(scripts.length(), 20)
  let seen : Set[String] = Set([])
  for script in scripts {
    assert_false(seen.contains(script.name()))
    seen.add(script.name())
  }
  assert_eq(@mbglot.Latin.name(), "Latin")
  assert_eq(@mbglot.Kana.name(), "Kana")
}
