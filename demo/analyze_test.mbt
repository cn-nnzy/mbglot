///|
test "analyze reports detection, top candidates and segments" {
  let text = "Здравствуйте, заказ не пришёл. Hi, could you check the tracking number for order 4471 please?"
  let result = @json.parse(@demo.analyze(text))
  guard result
    is {
      "detection": { "lang": "eng", "reliable": true, .. },
      "top": [{ "lang": "eng", "score": 1, .. }, _, _, _, _],
      "segments": [
        { "start": 0, "end": 31, "detection": { "lang": "bul", .. }, .. },
        { "start": 31, "end": 93, "detection": { "lang": "eng", .. }, .. },
      ],
      ..
    } else {
    fail("unexpected result: \{result.stringify()}")
  }
}

///|
test "analyze returns null detection for text it cannot identify" {
  for text in ["", "hi", "12345 67890 !!!"] {
    let result = @json.parse(@demo.analyze(text))
    guard result is { "detection": Null, "top": [], .. } else {
      fail("unexpected result for \{text}: \{result.stringify()}")
    }
  }
}

///|
test "segment offsets cover the input" {
  let text = "Bonjour à tous, merci pour votre aide. 这是一个测试句子，用来检查分段。"
  guard @json.parse(@demo.analyze(text)) is { "segments": Array(segments), .. } else {
    fail("no segments")
  }
  let mut expected = 0
  for segment in segments {
    guard segment is { "start": Number(start, ..), "end": Number(end, ..), .. } else {
      fail("bad segment \{segment.stringify()}")
    }
    assert_eq(start.to_int(), expected)
    expected = end.to_int()
  }
  assert_eq(expected, text.length())
}
