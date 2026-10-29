///|
test "a near tie in the Hindi belt goes to the language with more speakers" {
  let ranked = [(Bho, 1.0), (Mag, 0.97), (Hin, 0.95), (Mar, 0.9)]
  assert_eq(near_tie_prior(stats("कुछ शब्द").words, ranked), [
    (Hin, 1.0),
    (Mag, 0.97),
    (Bho, 0.95),
    (Mar, 0.9),
  ])
}

///|
test "the prior leaves clear leads and unrelated languages alone" {
  let far = [(Bho, 1.0), (Hin, 0.8)]
  assert_eq(near_tie_prior(stats("कुछ शब्द").words, far), far)
  let unrelated = [(Nld, 1.0), (Eng, 0.99), (Deu, 0.98)]
  assert_eq(near_tie_prior(stats("zo").words, unrelated), unrelated)
  assert_eq(near_tie_prior(stats("x").words, [(Hin, 1.0)]), [(Hin, 1.0)])
}

///|
test "evidence in the text overrides the prior" {
  // `tak` and `nak` are Malay; Indonesian has far more speakers.
  let ranked = [(Zlm, 1.0), (Ind, 0.99)]
  assert_eq(near_tie_prior(stats("saya tak nak pergi").words, ranked), ranked)
  assert_eq(near_tie_prior(stats("dia pergi").words, ranked), [
    (Ind, 1.0),
    (Zlm, 0.99),
  ])
}

///|
test "speakers" {
  assert_eq(Cmn.speakers(), 885)
  assert_eq(Hin.speakers(), 182)
  assert_eq(Kin.speakers(), 9)
  for lang in all_langs {
    assert_true(lang.speakers() >= 8)
  }
}
