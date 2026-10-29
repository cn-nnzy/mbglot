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

///|
test "dev and test split every language and length in half" {
  for length in @tatoeba.Length::all() {
    let all = @tatoeba.samples(length~)
    let dev = @tatoeba.samples(length~, split=Dev)
    let test_ = @tatoeba.samples(length~, split=Test)
    assert_eq(dev.length() + test_.length(), all.length())
    for lang in @tatoeba.languages() {
      let d = dev.filter(s => s.lang == lang).length()
      let t = test_.filter(s => s.lang == lang).length()
      assert_true(d == t || d == t + 1)
    }
    for sample in dev {
      assert_false(test_.contains(sample))
    }
  }
}
