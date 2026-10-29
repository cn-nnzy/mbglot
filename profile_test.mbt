///|
test "train keeps the most frequent trigrams, ties in order of appearance" {
  let profile = @mbglot.Profile::train("toy", "abab ab", size=3)
  assert_eq(profile.name(), "toy")
  // " ab" and "ab " occur twice, "aba", "bab" and "b a" once.
  assert_eq(profile.trigrams(), [" ab", "ab ", "aba"])
  assert_eq(@mbglot.Profile::train("toy", "abab ab").trigrams().length(), 5)
}

///|
test "train rejects bad input" {
  let error = (f : () -> @mbglot.Profile raise @mbglot.ProfileError) => {
    try f() catch {
      e => Some(e)
    } noraise {
      _ => None
    }
  }
  assert_eq(error(() => @mbglot.Profile::train("", "text")), Some(BadName("")))
  assert_eq(
    error(() => @mbglot.Profile::train("a\nb", "text")),
    Some(BadName("a\nb")),
  )
  assert_eq(
    error(() => @mbglot.Profile::train("x", "123 !!")),
    Some(NoTrigrams),
  )
  assert_eq(
    error(() => @mbglot.Profile::train("x", "text", size=0)),
    Some(BadSize(0)),
  )
}

///|
test "save and parse round-trip" {
  let profile = @mbglot.Profile::train(
    "support-es", "Hola, mi pedido llegó incompleto y falta una de las piezas.",
  )
  let saved = profile.save()
  assert_true(saved.has_prefix("mbglot profile 1\nsupport-es\n"))
  let back = @mbglot.Profile::parse(saved)
  assert_eq(back.name(), "support-es")
  assert_eq(back.trigrams(), profile.trigrams())
  let crlf = @mbglot.Profile::parse(saved.replace_all(old="\n", new="\r\n"))
  assert_eq(crlf.trigrams(), profile.trigrams())
  let builtin = @mbglot.Profile::of_lang(@mbglot.Eng).unwrap()
  assert_eq(
    @mbglot.Profile::parse(builtin.save()).trigrams(),
    builtin.trigrams(),
  )
}

///|
test "parse reports what is wrong" {
  let error = (saved : String) => {
    try @mbglot.Profile::parse(saved) catch {
      e => Some(e)
    } noraise {
      _ => None
    }
  }
  assert_eq(error(""), Some(BadHeader))
  assert_eq(error("mbglot profile 2\nx\nabc\n"), Some(BadHeader))
  assert_eq(error("mbglot profile 1\n\nabc\n"), Some(BadName("")))
  assert_eq(error("mbglot profile 1\nx\nabc\nab\n"), Some(BadTrigram(4)))
  assert_eq(error("mbglot profile 1\nx\nabc\nabc\n"), Some(BadTrigram(4)))
  assert_eq(error("mbglot profile 1\nx\n"), Some(NoTrigrams))
}

///|
test "built-in profiles" {
  let latin = @mbglot.Profile::of_lang(@mbglot.Srp).unwrap()
  let cyrillic = @mbglot.Profile::of_lang(@mbglot.Srp, script=Cyrillic).unwrap()
  assert_eq(latin.name(), cyrillic.name())
  assert_true(latin.trigrams() != cyrillic.trigrams())
  assert_true(@mbglot.Profile::of_lang(@mbglot.Rus, script=Latin) is None)
  let english = @mbglot.Profile::of_lang(@mbglot.Eng).unwrap()
  assert_eq(english.name(), "eng")
  assert_eq(english.trigrams().length(), 300)
  assert_true(@mbglot.Profile::of_lang(@mbglot.Jpn) is None)
  assert_eq(
    @mbglot.Profile::of_lang(@mbglot.Rus).map(p => p.name()),
    Some("rus"),
  )
}

///|
test "a classifier of franc's profiles ranks as franc does" {
  let franc = @mbglot.Options::new(mode=Franc)
  for
    text in [
      "Hola, mi pedido llegó incompleto y falta una de las piezas.", "Dobar dan, moja narudžba još nije stigla i nitko mi ne odgovara na poruke.",
      "Здравствуйте, я не могу войти в личный кабинет.",
    ] {
    let expected = @mbglot.rank(text, options=franc)
    let script = @mbglot.detect_script(text)
    let classifier = @mbglot.Classifier::new(
      expected.map(entry => @mbglot.Profile::of_lang(entry.0, script?).unwrap()),
    )
    assert_eq(
      classifier.rank(text),
      expected.map(entry => (entry.0.code(), entry.1)),
    )
  }
}

///|
test "a trained profile adds a language franc-min lacks" {
  // Esperanto, written for this test.
  let esperanto = @mbglot.Profile::train(
    "epo",
    "Saluton, mia nomo estas Petro kaj mi loĝas en granda urbo. " +
    "Mi tre ŝatas legi librojn kaj promeni en la parko kun mia hundo. " +
    "Hodiaŭ la vetero estas bela, do ni iros al la maro. " +
    "Ĉu vi volas veni kun ni? Ni manĝos fiŝojn kaj trinkos kafon. " +
    "La infanoj ludas en la ĝardeno, kaj iliaj gepatroj laboras hejme. " +
    "Esperanto estas facila lingvo, kiun oni povas lerni rapide.",
  )
  let langs : Array[@mbglot.Lang] = [Eng, Spa, Ita, Por, Fra, Deu]
  let profiles = langs.map(lang => @mbglot.Profile::of_lang(lang).unwrap())
  profiles.push(esperanto)
  let classifier = @mbglot.Classifier::new(profiles)
  assert_eq(classifier.names(), [
    "eng", "spa", "ita", "por", "fra", "deu", "epo",
  ])
  assert_eq(
    classifier.classify(
      "Ĉu vi scias, kie estas la stacidomo? Mi devas iri hejmen.",
    ),
    Some("epo"),
  )
  assert_eq(
    classifier.classify("The meeting has been moved to Thursday afternoon."),
    Some("eng"),
  )
  assert_eq(classifier.classify("Ĉu vi?"), None)
  assert_eq(classifier.classify("Ĉu vi?", min_length=0), Some("epo"))
}

///|
test "classifier needs distinct profiles" {
  let error = (profiles : Array[@mbglot.Profile]) => {
    try @mbglot.Classifier::new(profiles) catch {
      e => Some(e)
    } noraise {
      _ => None
    }
  }
  let english = @mbglot.Profile::of_lang(@mbglot.Eng).unwrap()
  assert_eq(error([]), Some(NoProfiles))
  assert_eq(error([english, english]), Some(DuplicateName("eng")))
}
