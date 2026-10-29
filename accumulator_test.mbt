///|
/// `text` cut into pieces at positions chosen by a small linear
/// congruential generator seeded with `seed`, never inside a surrogate
/// pair.
fn pieces(text : String, seed : Int32) -> Array[String] {
  let out = []
  let mut state = seed
  let mut start = 0
  while start < text.length() {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF
    let mut end = (start + 1 + state % 25).min(text.length())
    if end < text.length() {
      let unit = text.unsafe_get(end).to_int()
      if unit >= 0xDC00 && unit <= 0xDFFF {
        end += 1
      }
    }
    out.push(text.view(start_offset=start, end_offset=end).to_owned())
    start = end
  }
  out
}

///|
test "an accumulator agrees with detect on the chunks joined by line breaks" {
  let samples = @tatoeba.samples()
  let modes : Array[@mbglot.Mode] = [Franc, Enhanced]
  for mode in modes {
    let options = @mbglot.Options::new(mode~)
    let detector = @mbglot.Detector::new(options~)
    let mut i = 0
    while i < samples.length() {
      let chunks = pieces(samples[i].text, i)
      let joined = chunks.join("\n")
      let acc = detector.accumulator()
      for chunk in chunks {
        acc.feed(chunk)
      }
      assert_eq(acc.length(), joined.length())
      assert_eq(acc.detect(), detector.detect(joined), msg=joined)
      assert_eq(acc.rank(), detector.rank(joined), msg=joined)
      i += 13
    }
  }
}

///|
test "the answer can be asked for after every chunk" {
  let acc = @mbglot.Accumulator::new()
  assert_eq(acc.detect(), None)
  acc.feed("ok")
  assert_eq(acc.detect(), None)
  acc.feed("Hola, ¿cómo estás?")
  assert_eq(acc.detect().map(d => d.lang), Some(@mbglot.Spa))
  acc.feed("Muy bien, gracias. ¿Y tú? Tengo una pregunta sobre mi pedido.")
  let d = acc.detect().unwrap()
  assert_eq(d.lang, @mbglot.Spa)
  assert_true(d.reliable)
  assert_eq(
    acc.length(),
    [
      "ok", "Hola, ¿cómo estás?", "Muy bien, gracias. ¿Y tú? Tengo una pregunta sobre mi pedido.",
    ]
    .join("\n")
    .length(),
  )
}

///|
test "a long stream counts every chunk" {
  // franc samples only the first 2048 code units of one text; an
  // accumulator weighs the German that follows a long English opening.
  let texts = (lang : @mbglot.Lang) => {
    @tatoeba.samples(length=Long)
    .filter(sample => sample.lang == lang)
    .map(sample => sample.text)
    .join(" ")
  }
  let english = texts(Eng)
  let german = texts(Deu)
  assert_true(english.length() > 2048 && german.length() > english.length())
  let acc = @mbglot.Accumulator::new()
  acc.feed(english)
  assert_eq(acc.detect().map(d => d.lang), Some(@mbglot.Eng))
  acc.feed(german)
  assert_eq(acc.detect().map(d => d.lang), Some(@mbglot.Deu))
  assert_eq(
    @mbglot.detect(english + "\n" + german).map(d => d.lang),
    Some(@mbglot.Eng),
  )
}

///|
test "reset forgets the stream" {
  let acc = @mbglot.Accumulator::new(options=@mbglot.Options::new(mode=Franc))
  acc.feed("Guten Tag, meine Bestellung ist leider noch nicht angekommen.")
  assert_eq(acc.detect().map(d => d.lang), Some(@mbglot.Deu))
  acc.reset()
  assert_eq(acc.length(), 0)
  assert_eq(acc.detect(), None)
  acc.feed("Bonjour, je n'ai toujours pas reçu ma facture du mois dernier.")
  assert_eq(
    acc.detect(),
    @mbglot.detect(
      "Bonjour, je n'ai toujours pas reçu ma facture du mois dernier.",
      options=@mbglot.Options::new(mode=Franc),
    ),
  )
}

///|
test "markup is removed chunk by chunk" {
  let acc = @mbglot.Accumulator::new()
  let markup = "@dana see https://example.com/a/very/long/path"
  acc.feed(markup)
  assert_eq(acc.length(), @mbglot.strip_markup(markup).text.length())
  assert_true(acc.length() < 10)
  acc.feed("Merci beaucoup pour votre aide, à demain !")
  assert_eq(acc.detect().map(d => d.lang), Some(@mbglot.Fra))
}
