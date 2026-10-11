///|
fn langs(segments : Array[@mbglot.Segment]) -> Array[@mbglot.Lang?] {
  segments.map(s => s.detection.map(d => d.lang))
}

///|
fn assert_covers(
  text : String,
  segments : Array[@mbglot.Segment],
) -> Unit raise {
  let mut offset = 0
  let joined = StringBuilder()
  for s in segments {
    assert_eq(s.start, offset)
    assert_true(s.end > s.start)
    assert_eq(
      s.text,
      text.view(start_offset=s.start, end_offset=s.end).to_owned(),
    )
    joined.write_string(s.text)
    offset = s.end
  }
  assert_eq(offset, text.length())
  assert_eq(joined.to_string(), text)
}

///|
test "two languages in consecutive sentences" {
  let text = "Hello, my order has not arrived yet and I need it for Friday. " +
    "Hola, mi pedido no ha llegado todavía y lo necesito para el viernes."
  let result = @mbglot.segments(text)
  assert_covers(text, result)
  assert_eq(langs(result), [Some(@mbglot.Eng), Some(@mbglot.Spa)])
  assert_eq(result[1].start, 62)
  assert_true(result[1].text.has_prefix("Hola"))
}

///|
test "script changes split segments" {
  let text = "Здравствуйте, заказ не пришёл. " +
    "Hi, could you check the tracking number for order 4471 please? " +
    "谢谢，麻烦尽快处理一下这个问题。"
  let result = @mbglot.segments(text)
  assert_covers(text, result)
  assert_eq(result.map(s => s.detection.unwrap().script), [
    @mbglot.Cyrillic,
    @mbglot.Latin,
    @mbglot.Han,
  ])
  assert_eq(result[1].detection.unwrap().lang, @mbglot.Eng)
  assert_eq(result[2].detection.unwrap().lang, @mbglot.Cmn)
}

///|
test "Japanese keeps kana and kanji together" {
  let text = "日本語のメールです。よろしくお願いします。" +
    "This part is written in English for the overseas team."
  let result = @mbglot.segments(text)
  assert_covers(text, result)
  assert_eq(langs(result), [Some(@mbglot.Jpn), Some(@mbglot.Eng)])
}

///|
test "short pieces join a neighbour instead of being guessed" {
  let text = "Danke! The device works fine now, thank you for the quick replacement."
  let result = @mbglot.segments(text)
  assert_covers(text, result)
  assert_eq(langs(result), [Some(@mbglot.Eng)])
}

///|
test "emoji between sentences of one language" {
  let text = "Bonjour, je n'ai toujours pas reçu ma facture du mois dernier. 😀😀 " +
    "Merci d'avance pour votre aide."
  let result = @mbglot.segments(text)
  assert_covers(text, result)
  assert_eq(langs(result), [Some(@mbglot.Fra)])
}

///|
test "nothing identifiable" {
  assert_eq(@mbglot.segments(""), [])
  for text in ["ok", "😀😀😀", "12345 67890 !!!", "   \n  "] {
    let result = @mbglot.segments(text)
    assert_covers(text, result)
    assert_eq(langs(result), [None])
  }
}

///|
test "offsets count UTF-16 code units" {
  let han = "\u{20000}\u{20001}\u{20002}\u{20003}\u{20004}\u{20005}"
  let text = han + "and then a sentence written in plain English words."
  let result = @mbglot.segments(text)
  assert_covers(text, result)
  assert_eq(langs(result), [Some(@mbglot.Cmn), Some(@mbglot.Eng)])
  assert_eq(result[1].start, 12)
}

///|
test "options apply to every segment" {
  let text = "Hello, my order has not arrived yet and I need it for Friday. " +
    "Hola, mi pedido no ha llegado todavía y lo necesito para el viernes."
  let options = @mbglot.Options::new(allow=[@mbglot.Eng, @mbglot.Spa])
  let result = @mbglot.segments(text, options~)
  assert_covers(text, result)
  assert_eq(langs(result), [Some(@mbglot.Eng), Some(@mbglot.Spa)])
}

///|
test "neighbouring segments differ in language" {
  let texts = [
    "Thanks. Merci. Danke. This is a longer English sentence to finish the message.",
    "Order 4471. Заказ 4471 не пришёл, пожалуйста, проверьте доставку. Thank you very much for checking it.",
    "Line one in English here.\nLínea dos en español aquí, con más palabras para ayudar.",
  ]
  for text in texts {
    let result = @mbglot.segments(text)
    assert_covers(text, result)
    for i in 1..<result.length() {
      assert_true(langs(result)[i - 1] != langs(result)[i])
    }
  }
}
