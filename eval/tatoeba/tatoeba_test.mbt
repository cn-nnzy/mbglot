///|
test "every length has samples and lengths partition the corpus" {
  let all = @tatoeba.samples()
  let mut sum = 0
  for length in @tatoeba.Length::all() {
    let part = @tatoeba.samples(length~)
    assert_true(part.length() > 1000)
    sum += part.length()
  }
  assert_eq(sum, all.length())
}

///|
test "sample lengths match their class" {
  for sample in @tatoeba.samples(length=Short) {
    assert_true(sample.text.length() >= 10 && sample.text.length() <= 30)
  }
  for sample in @tatoeba.samples(length=Medium) {
    assert_true(sample.text.length() >= 31 && sample.text.length() <= 80)
  }
  for sample in @tatoeba.samples(length=Long) {
    assert_true(sample.text.length() >= 150)
  }
}

///|
test "covered languages" {
  let langs = @tatoeba.languages()
  assert_eq(langs.length(), 72)
  for missing in [@mbglot.Qug, @mbglot.Hms, @mbglot.Zyb, @mbglot.Mag] {
    assert_false(langs.contains(missing))
  }
  for sample in @tatoeba.samples() {
    assert_true(langs.contains(sample.lang))
  }
}
