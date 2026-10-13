///|
fn kinds(text : String) -> Array[(String, @mbglot.Markup)] {
  @mbglot.strip_markup(text)
  .removed()
  .map(r => {
    (text.view(start_offset=r.start, end_offset=r.end).to_owned(), r.kind)
  })
}

///|
test "urls" {
  assert_eq(kinds("see https://example.com/a?b=1, then"), [
    ("https://example.com/a?b=1", Url),
  ])
  assert_eq(kinds("(www.example.org/x_(y))."), [("www.example.org/x_(y)", Url)])
  assert_eq(kinds("HTTP://EXAMPLE.COM"), [("HTTP://EXAMPLE.COM", Url)])
  // A scheme inside a word or without an address is not a URL.
  assert_eq(kinds("xhttp://a.b"), [])
  assert_eq(kinds("http:// and www. alone"), [])
}

///|
test "email addresses and mentions" {
  assert_eq(kinds("write to anna.k+tickets@mail.example.de today"), [
    ("anna.k+tickets@mail.example.de", Email),
  ])
  assert_eq(kinds("thanks @support_team!"), [("@support_team", Mention)])
  // No top-level domain of letters: not an address.
  assert_eq(kinds("a@b.c1 and 3@4"), [])
  assert_eq(kinds("mail@host"), [])
}

///|
test "hashtags need a letter and may use any script" {
  assert_eq(kinds("#ordertracking #привет #日本 #1 a#b"), [
    ("#ordertracking", Hashtag),
    ("#привет", Hashtag),
    ("#日本", Hashtag),
  ])
}

///|
test "html tags, comments, entities and code elements" {
  assert_eq(kinds("<p class=\"x > y\">Hola</p>"), [
    ("<p class=\"x > y\">", HtmlTag),
    ("</p>", HtmlTag),
  ])
  assert_eq(kinds("a <!-- note --> b &amp; c &#233; d &#x1F600;"), [
    ("<!-- note -->", HtmlTag),
    ("&amp;", HtmlEntity),
    ("&#233;", HtmlEntity),
    ("&#x1F600;", HtmlEntity),
  ])
  assert_eq(kinds("x <code>let a = 1</code> y <script>f()</script>"), [
    ("<code>let a = 1</code>", Code),
    ("<script>f()</script>", Code),
  ])
  // Comparisons and stray ampersands are text.
  assert_eq(kinds("1 < 2 and 3 > 2, R&D, a & b, &nope"), [])
}

///|
test "markdown code spans and fences" {
  assert_eq(kinds("run `moon test` now"), [("`moon test`", Code)])
  assert_eq(kinds("``a ` b`` c"), [("``a ` b``", Code)])
  assert_eq(kinds("text\n```\ncode\n```\nmore"), [("```\ncode\n```", Code)])
  assert_eq(kinds("open ```\nnever closed"), [("```\nnever closed", Code)])
  assert_eq(kinds("it`s fine"), [])
}

///|
test "removed stretches become one space and offsets map back" {
  let text = "Hi @dana, see https://x.io/a 😀 ok"
  let s = @mbglot.strip_markup(text)
  assert_eq(s.text(), "Hi  , see   😀 ok")
  for i in 0..<s.text().length() {
    let o = s.original_offset(i)
    let kept = s.text().unsafe_get(i)
    // A kept unit maps to the same unit; a placeholder space maps to the
    // start of what it replaced.
    if kept != ' ' || text.unsafe_get(o) == ' ' {
      assert_eq(text.unsafe_get(o), kept)
    } else {
      assert_true(text.unsafe_get(o) == '@' || text.unsafe_get(o) == 'h')
    }
  }
  assert_eq(s.original_offset(s.text().length()), text.length())
  assert_eq(s.original_offset(-5), 0)
  assert_eq(s.original_offset(1000), text.length())
}

///|
test "text without markup is unchanged" {
  let text = "Nothing to remove here: 3 < 4, a&b, it's #1."
  let s = @mbglot.strip_markup(text)
  assert_eq(s.text(), text)
  assert_eq(s.removed(), [])
  for i in 0..<=text.length() {
    assert_eq(s.original_offset(i), i)
  }
}

///|
test "markup no longer decides the language" {
  let text = "Il mio ordine non è arrivato " +
    "https://www.example.com/the/order/status/page/for/customers/with/questions"
  assert_eq(@mbglot.detect(text).map(d => d.lang), Some(@mbglot.Ita))
  // Without stripping, the English words of the address win.
  let raw = @mbglot.Options::new(strip_markup=false)
  assert_eq(
    @mbglot.detect(text, options=raw).map(d => d.lang),
    Some(@mbglot.Eng),
  )
}

///|
test "text that is only markup is not identified" {
  assert_eq(@mbglot.detect("https://example.com/some/long/path/here"), None)
  assert_eq(@mbglot.detect("<div><span></span></div>"), None)
}

///|
test "segments keep exact offsets into the original text" {
  let text = "Hello, my order <b>4471</b> has not arrived yet, see https://t.co/x. " +
    "Hola, mi pedido no ha llegado todavía y lo necesito para el viernes."
  let result = @mbglot.segments(text)
  let mut offset = 0
  for s in result {
    assert_eq(s.start, offset)
    assert_eq(
      s.text,
      text.view(start_offset=s.start, end_offset=s.end).to_owned(),
    )
    offset = s.end
  }
  assert_eq(offset, text.length())
  assert_eq(result.map(s => s.detection.map(d => d.lang)), [
    Some(@mbglot.Eng),
    Some(@mbglot.Spa),
  ])
  assert_true(result[1].text.has_prefix("Hola"))
}
