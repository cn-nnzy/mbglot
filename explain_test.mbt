///|
test "explain names the pass that decided" {
  let cases : Array[(String, Array[@mbglot.Step])] = [
    (
      "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio.",
      [Trigrams(Spa), RelatedLanguages(Por, ["ç", "o", "do"])],
    ),
    (
      "это мой дом",
      [Trigrams(Koi), CommonWords(Rus, ["это", "мой"])],
    ),
    (
      "我们公司の产品质量很好，欢迎大家购买。",
      [Trigrams(Jpn), ScriptShare(Cmn)],
    ),
    (
      "मैं कल बाजार गया था और वहाँ से सब्जियाँ खरीदीं।",
      [Trigrams(Bho), NearTie(Hin, Bho)],
    ),
    (
      "Saya tidak tahu di mana dia.",
      [Trigrams(Ind), RelatedLanguages(Zlm, ["saya"])],
    ),
    ("Hi, I was charged twice for my subscription this month.", [Trigrams(Eng)]),
  ]
  for case in cases {
    let explanation = @mbglot.explain(case.0)
    assert_eq(explanation.steps, case.1)
    let last = match case.1.last() {
      Some(Trigrams(l)) | Some(ScriptShare(l)) => l
      Some(CommonWords(l, _)) | Some(RelatedLanguages(l, _)) => l
      Some(NearTie(l, _)) => l
      None => panic()
    }
    assert_eq(explanation.detection.map(d => d.lang), Some(last))
  }
}

///|
test "franc mode has a single step" {
  let franc = @mbglot.Options::new(mode=Franc)
  let explanation = @mbglot.explain("это мой дом", options=franc)
  assert_eq(explanation.steps, [Trigrams(Koi)])
  assert_eq(
    explanation.detection,
    @mbglot.detect("это мой дом", options=franc),
  )
}

///|
test "trigram gains favour franc's choice" {
  let text = "Hi, I was charged twice for my subscription this month."
  let explanation = @mbglot.explain(
    text,
    options=@mbglot.Options::new(mode=Franc),
  )
  let detection = explanation.detection.unwrap()
  let trigrams = explanation.trigrams
  assert_true(trigrams.length() > 10)
  let mut total = 0
  for i, t in trigrams {
    assert_eq(t.trigram.length(), 3)
    assert_true(t.gain != 0)
    if i > 0 {
      assert_true(trigrams[i - 1].gain >= t.gain)
    }
    total += t.gain
  }
  // The gains add up to the runner-up's distance minus English's, which
  // is positive because franc ranked English first.
  assert_true(total > 0)
  assert_true(detection.margin > 0.0)
  assert_eq(trigrams[0].rank is Some(_), true)
}

///|
test "nothing to explain" {
  let explanation = @mbglot.explain("ok")
  assert_eq(explanation.detection, None)
  assert_eq(explanation.steps, [])
  assert_eq(explanation.trigrams, [])
  let single = @mbglot.explain(
    "您好，我昨天下的订单到现在还没有发货。",
  )
  assert_eq(single.steps, [Trigrams(Cmn)])
  assert_eq(single.trigrams, [])
}

///|
test "a detector explains with its options" {
  let detector = @mbglot.Detector::new(
    options=@mbglot.Options::new(deny=[@mbglot.Por]),
  )
  let explanation = detector.explain(
    "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio.",
  )
  assert_eq(explanation.detection.map(d => d.lang), Some(@mbglot.Spa))
  assert_eq(explanation.steps, [Trigrams(Spa)])
}
