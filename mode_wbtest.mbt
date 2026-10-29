///|
test "Mode::Franc ranks exactly as franc-min" {
  let failures = []
  for case in golden_cases {
    let (name, text, allow, deny, min_length, expected) = case
    let options = Options::new(
      allow?=if allow.is_empty() { None } else { Some(codes_to_langs(allow)) },
      deny=codes_to_langs(deny),
      min_length~,
      mode=Franc,
    ) catch {
      _ => continue
    }
    let actual = match rank(text, options~) {
      [] => [("und", 1.0)]
      ranked => ranked.map(r => (r.0.code(), r.1))
    }
    if actual != expected {
      failures.push(name)
    }
  }
  assert_eq(failures, [])
}

///|
test "Mode::Franc does not strip markup unless asked" {
  assert_false(Options::new(mode=Franc).strip_markup())
  assert_true(Options::new(mode=Franc, strip_markup=true).strip_markup())
  assert_true(Options::new().strip_markup())
  assert_eq(Options::new().mode(), Enhanced)
}

///|
test "words are lowercased and split at punctuation" {
  assert_eq(words_of("¿Qué TAL, amigo? Ça va—bien. l'eau 42x"), [
    "qué", "tal", "amigo", "ça", "va", "bien", "l'eau", "x",
  ])
  assert_eq(words_of("یہ، کیا؟ ۔"), ["یہ", "کیا"])
}

///|
test "occurrences do not overlap" {
  assert_eq(occurrences("aaaa", "aa"), 2)
  assert_eq(occurrences("lhalh", "lh"), 2)
  assert_eq(occurrences("", "x"), 0)
}

///|
test "the pass keeps franc's scores and only reorders" {
  let ranked = [(Spa, 1.0), (Ita, 0.8), (Por, 0.7), (Fra, 0.7), (Ron, 0.1)]
  let out = settle_confusables(stats("não é o que eu quero"), ranked, [], [])
  assert_eq(out, [(Por, 1.0), (Ita, 0.8), (Fra, 0.7), (Spa, 0.7), (Ron, 0.1)])
  let before = ranked.map(r => r.1)
  let after = out.map(r => r.1)
  before.sort()
  after.sort()
  assert_eq(after, before)
}

///|
test "no change without clear evidence, or when the winner is denied" {
  let ranked = [(Spa, 1.0), (Por, 0.9)]
  // No markers or listed words.
  assert_eq(settle_confusables(stats("xyz qwrt"), ranked, [], []), ranked)
  // As much evidence for both: franc's order stays.
  assert_eq(settle_confusables(stats("el o"), ranked, [], []), ranked)
  // Evidence for Portuguese, but Portuguese is denied.
  assert_eq(settle_confusables(stats("não você"), ranked, [], [Por]), ranked)
  // franc's choice outside every group.
  let eng = [(Eng, 1.0), (Por, 0.5)]
  assert_eq(settle_confusables(stats("não você"), eng, [], []), eng)
}

///|
test "a language without a profile in the script can win" {
  // franc-min has Kurdish only in Latin script; Sorani in Arabic script
  // comes out as Persian.
  let ranked = [(Pes, 1.0), (Urd, 0.9), (Arb, 0.8)]
  let out = settle_confusables(
    stats("نامەوێت کارە پیسەکەت بکەم"),
    ranked,
    [],
    [],
  )
  assert_eq(out, [(Ckb, 1.0), (Urd, 0.9), (Pes, 0.9), (Arb, 0.8)])
  // Not when the options exclude it.
  assert_eq(
    settle_confusables(
      stats("نامەوێت کارە پیسەکەت بکەم"),
      ranked,
      [Pes, Urd, Arb],
      [],
    ),
    ranked,
  )
}
