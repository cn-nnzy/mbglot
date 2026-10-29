///|
test "languages" {
  let codes = @full.languages()
  assert_eq(codes.length(), 178)
  for
    code in [
      "eng", "epo", "heb", "kat", "hye", "khm", "cat", "glg", "dan", "nob",
    ] {
    assert_true(codes.contains(code), msg=code)
  }
  // franc-min's languages are all in the full set.
  for lang in @mbglot.Lang::all() {
    assert_true(codes.contains(lang.code()), msg=lang.code())
  }
}

///|
test "languages franc-min lacks" {
  let cases = [
    ("Ĉu vi scias, kie estas la stacidomo? Mi devas iri hejmen.", "epo"),
    ("Bon dia, voldria saber quan arribarà la meva comanda.", "cat"),
    (
      "שלום, ההזמנה שלי עדיין לא הגיעה. אפשר לבדוק?",
      "heb",
    ),
    (
      "გამარჯობა, ჩემი შეკვეთა ჯერ არ მოსულა.",
      "kat",
    ),
  ]
  for case in cases {
    assert_eq(@full.franc(case.0), case.1, msg=case.0)
  }
}

///|
test "und, allow and deny as in franc" {
  assert_eq(@full.franc_all("hi"), [("und", 1.0)])
  assert_eq(@full.franc_all("12345 67890 !!!"), [("und", 1.0)])
  assert_eq(@full.franc("123", min_length=0), "und")
  assert_eq(@full.franc("hi", min_length=0), "tso")
  let text = "Bon dia, voldria saber quan arribarà la meva comanda."
  assert_eq(@full.franc(text, deny=["cat"]) != "cat", true)
  assert_eq(@full.franc(text, allow=["spa", "por"]), "spa")
  assert_eq(@full.franc_all(text, allow=["xyz"]), [("und", 1.0)])
  assert_eq(
    @full.franc("您好，我的订单还没有到。", deny=["cmn"]),
    "und",
  )
}
