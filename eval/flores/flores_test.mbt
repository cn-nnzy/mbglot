///|
test "every language has the same 40 sentence positions" {
  let langs = @flores.languages()
  assert_eq(langs.length(), 68)
  let samples = @flores.samples()
  assert_eq(samples.length(), 68 * 40)
  for lang in langs {
    assert_eq(samples.filter(s => s.lang == lang).length(), 40)
  }
  for missing in [@mbglot.Pbu, @mbglot.Qug, @mbglot.Skr, @mbglot.Koi] {
    assert_false(langs.contains(missing))
  }
}

///|
test "texts are whole sentences without stray whitespace" {
  for sample in @flores.samples() {
    assert_true(sample.text.length() >= 10, msg=sample.text)
    assert_eq(sample.text.trim().to_owned(), sample.text)
    assert_false(sample.text.contains("  "))
  }
}
