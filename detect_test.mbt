///|
test "detect common languages" {
  let cases = [
    ("Hi, I was charged twice for my subscription this month.", @mbglot.Eng),
    (
      "Hola, mi pedido llegó incompleto y falta una de las piezas.",
      @mbglot.Spa,
    ),
    (
      "Здравствуйте, я не могу войти в личный кабинет.",
      @mbglot.Rus,
    ),
    (
      "مرحبا، لم يصلني رمز التحقق على هاتفي رغم أنني طلبته.",
      @mbglot.Arb,
    ),
  ]
  for case in cases {
    let detection = @mbglot.detect(case.0).unwrap()
    assert_eq(detection.lang, case.1)
  }
}

///|
test "single-script languages" {
  let detection = @mbglot.detect(
    "您好，我昨天下的订单到现在还没有发货。",
  ).unwrap()
  assert_eq(detection.lang, @mbglot.Cmn)
  assert_eq(detection.script, @mbglot.Han)
  assert_eq(detection.confidence, 1.0)
  assert_eq(
    @mbglot.detect("注文した商品がまだ届いておりません。").unwrap().lang,
    @mbglot.Jpn,
  )
  assert_eq(@mbglot.rank("안녕하세요, 결제는 완료되었습니다"), [
    (@mbglot.Kor, 1.0),
  ])
}

///|
test "no detection without letters or below min_length" {
  assert_eq(@mbglot.detect(""), None)
  assert_eq(@mbglot.detect("   \t\n      "), None)
  assert_eq(@mbglot.detect("1234567890 0987654321"), None)
  assert_eq(@mbglot.detect("😀😃😄😁😆😅🤣😂🙂🙃"), None)
  assert_eq(@mbglot.detect("?!?!... --- ### !!!"), None)
  assert_eq(@mbglot.detect("Thank you"), None)
  assert_true(@mbglot.detect("Thank you!") is Some(_))
  assert_eq(@mbglot.rank("Thank you"), [])
}

///|
test "rank is sorted and normalised" {
  let ranked = @mbglot.rank(
    "Guten Tag, die Lieferung ist beschädigt angekommen. Ich möchte das Gerät umtauschen.",
  )
  assert_eq(ranked.length(), 44)
  assert_eq(ranked[0], (@mbglot.Deu, 1.0))
  for i in 1..<ranked.length() {
    assert_true(ranked[i - 1].1 >= ranked[i].1)
    assert_true(ranked[i].1 >= 0.0 && ranked[i].1 <= 1.0)
  }
}

///|
test "options restrict candidates" {
  let text = "Hola, mi pedido llegó incompleto y falta una de las piezas."
  let only = @mbglot.Options::new(allow=[@mbglot.Eng, @mbglot.Por])
  let ranked = @mbglot.rank(text, options=only)
  assert_eq(ranked.map(r => r.0), [@mbglot.Por, @mbglot.Eng])
  let no_spa = @mbglot.Options::new(deny=[@mbglot.Spa])
  assert_true(@mbglot.detect(text, options=no_spa).unwrap().lang != @mbglot.Spa)
  let han_only = @mbglot.Options::new(allow=[@mbglot.Cmn])
  assert_eq(@mbglot.detect(text, options=han_only), None)
  let no_cmn = @mbglot.Options::new(deny=[@mbglot.Cmn])
  assert_eq(
    @mbglot.detect(
      "您好，我昨天下的订单到现在还没有发货。",
      options=no_cmn,
    ),
    None,
  )
}

///|
test "min_length option" {
  let zero = @mbglot.Options::new(min_length=0)
  assert_true(@mbglot.detect("ok", options=zero) is Some(_))
  assert_eq(@mbglot.detect("", options=zero), None)
  let forty = @mbglot.Options::new(min_length=40)
  assert_eq(
    @mbglot.detect("This sentence is clearly English.", options=forty),
    None,
  )
  assert_eq(forty.min_length(), 40)
}

///|
fn options_error(
  make : () -> @mbglot.Options raise @mbglot.OptionsError,
) -> @mbglot.OptionsError? {
  try make() catch {
    e => Some(e)
  } noraise {
    _ => None
  }
}

///|
test "invalid options are errors" {
  assert_eq(
    options_error(() => @mbglot.Options::new(allow=[])),
    Some(@mbglot.EmptyAllow),
  )
  assert_eq(
    options_error(() => {
      @mbglot.Options::new(allow=[@mbglot.Eng, @mbglot.Fra], deny=[@mbglot.Fra])
    }),
    Some(@mbglot.AllowDenyOverlap(@mbglot.Fra)),
  )
  assert_eq(
    options_error(() => @mbglot.Options::new(min_length=-1)),
    Some(@mbglot.NegativeMinLength(-1)),
  )
  assert_eq(
    options_error(() => @mbglot.Options::new(deny=@mbglot.Lang::all())),
    Some(@mbglot.DenyAll),
  )
  assert_eq(options_error(() => @mbglot.Options::new(deny=[@mbglot.Eng])), None)
}

///|
test "options copy their inputs" {
  let allow = [@mbglot.Eng]
  let options = @mbglot.Options::new(allow~)
  allow.push(@mbglot.Fra)
  assert_eq(options.allow(), [@mbglot.Eng])
  assert_eq(options.deny(), [])
}

///|
test "reliable needs the minimum length" {
  let base = "Hi, I was charged twice for my subscription this month."
  let at_limit = base.view(end_offset=@mbglot.reliable_min_length).to_owned()
  let below = base.view(end_offset=@mbglot.reliable_min_length - 1).to_owned()
  let long = @mbglot.detect(at_limit).unwrap()
  let short = @mbglot.detect(below).unwrap()
  assert_eq(long.lang, @mbglot.Eng)
  assert_eq(short.lang, @mbglot.Eng)
  assert_true(long.confidence >= @mbglot.reliable_min_margin)
  assert_true(short.confidence >= @mbglot.reliable_min_margin)
  assert_true(long.reliable)
  assert_false(short.reliable)
}

///|
test "reliable needs the minimum margin" {
  let close = @mbglot.detect(
    "Dobar dan, moja narudžba još nije stigla i nitko mi ne odgovara na poruke.",
  ).unwrap()
  assert_true(close.confidence < @mbglot.reliable_min_margin)
  assert_false(close.reliable)
  let clear = @mbglot.detect(
    "Hi, I was charged twice for my subscription this month. Could you refund it?",
  ).unwrap()
  assert_true(clear.confidence >= @mbglot.reliable_min_margin)
  assert_true(clear.reliable)
}

///|
test "confidence is the margin to the runner-up" {
  let text = "Bonjour, je n'ai toujours pas reçu ma facture du mois dernier."
  let ranked = @mbglot.rank(text)
  let detection = @mbglot.detect(text).unwrap()
  assert_eq(detection.lang, ranked[0].0)
  assert_eq(detection.confidence, ranked[0].1 - ranked[1].1)
  assert_eq(detection.script, @mbglot.Latin)
}
