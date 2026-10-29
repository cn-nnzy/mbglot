///|
/// The statistics of `text` with its words, as `Mode::Enhanced` sees it.
fn stats(text : String) -> TextStats {
  TextStats::of(text, with_words=true)
}

///|
test "common words move a close candidate to the top" {
  let ranked = [(Ita, 1.0), (Spa, 0.97), (Por, 0.95), (Fra, 0.6)]
  // Two Spanish words ("el", "es") against none for Italian.
  assert_eq(short_text_signal(stats("el gato es negro"), ranked), [
    (Spa, 1.0),
    (Ita, 0.97),
    (Por, 0.95),
    (Fra, 0.6),
  ])
}

///|
test "a candidate far behind is not promoted by one word" {
  let ranked = [(Ita, 1.0), (Fra, 0.6)]
  assert_eq(short_text_signal(stats("le gatto nero"), ranked), ranked)
}

///|
test "ties keep franc's order" {
  // "de" is a common word of Spanish and Portuguese alike.
  let ranked = [(Por, 1.0), (Spa, 1.0)]
  assert_eq(short_text_signal(stats("casa de papel"), ranked), ranked)
}

///|
test "long texts, single candidates and texts without words are left alone" {
  let ranked = [(Ita, 1.0), (Spa, 0.97)]
  let long = "el gato es negro y el perro es blanco, pero los dos duermen"
  assert_true(long.length() >= short_text_length)
  assert_eq(short_text_signal(stats(long), ranked), ranked)
  assert_eq(short_text_signal(stats("el gato"), [(Ita, 1.0)]), [(Ita, 1.0)])
  assert_eq(short_text_signal(stats("123 456"), ranked), ranked)
}

///|
test "languages without a list get no bonus" {
  assert_eq(stop_word_hits(Eng, stats("the cat and the dog").words), 3)
  assert_eq(stop_word_hits(Yor, stats("the a").words), 0)
  assert_eq(stop_word_hits(Eng, stats("the a cat").words), 2)
}

///|
test "common-word lists are lowercase single words without duplicates" {
  for entry in stop_words {
    let (lang, list) = entry
    let seen : Set[String] = Set([])
    for word in list {
      assert_true(
        word == words_of(word).join(" "),
        msg="\{lang.code()}: \{word}",
      )
      assert_false(seen.contains(word), msg="\{lang.code()}: \{word} twice")
      seen.add(word)
    }
  }
}

///|
test "Mode::Franc ignores the word signal" {
  let text = "el gato es negro"
  let franc = rank(text, options=Options::new(mode=Franc))
  assert_eq(franc, franc_all(text, [], [], 10).unwrap().1)
}
