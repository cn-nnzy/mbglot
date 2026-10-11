///|
fn clean(text : String) -> String {
  units_to_string(clean_units(text))
}

///|
test "clean replaces ASCII punctuation and digits with spaces" {
  assert_eq(clean("Hello, World!"), "hello world")
  assert_eq(clean("  It's 2024: TEST-case  "), "it s test case")
  assert_eq(clean("e-mail@example.com"), "e mail example com")
  assert_eq(clean("123 !!! 456"), "")
  assert_eq(clean(""), "")
}

///|
test "clean keeps characters outside U+0021..U+0040" {
  assert_eq(clean("[a_b]{c|d}~e`f^"), "[a_b]{c|d}~e`f^")
  assert_eq(clean("¿Qué? ¡Sí!"), "¿qué ¡sí")
  assert_eq(clean("«Да» — нет"), "«да» — нет")
}

///|
test "clean collapses and trims JavaScript whitespace" {
  assert_eq(clean("a\t\n\r\u{0B}\u{0C}b"), "a b")
  assert_eq(clean("a\u{A0}\u{1680}\u{2003}\u{2028}\u{202F}\u{3000}b"), "a b")
  assert_eq(clean("\u{FEFF} a \u{FEFF}"), "a")
  assert_eq(clean("a\u{180E}b"), "a\u{180E}b")
  assert_eq(clean("a\u{200B}b"), "a\u{200B}b")
}

///|
test "lowercasing follows JavaScript toLowerCase" {
  assert_eq(clean("ÀÉÎÕÜ ŁŒ"), "àéîõü łœ")
  assert_eq(clean("ПРИВЕТ ЁЖ"), "привет ёж")
  assert_eq(clean("ẞ"), "ß")
  assert_eq(clean("\u{1C90}"), "\u{10D0}")
  assert_eq(clean("\u{10400}"), "\u{10428}")
  assert_eq(clean("ǅ"), "ǆ")
  assert_eq(clean("Ⅻ"), "ⅻ")
}

///|
test "dotted capital I lowercases to two code units" {
  let lowered = clean("İ")
  assert_eq(lowered, "i\u{0307}")
  assert_eq(lowered.length(), 2)
}

///|
test "capital sigma becomes final sigma at the end of a word" {
  assert_eq(clean("ΟΔΟΣ ΟΔΟΣ."), "οδος οδος")
  assert_eq(clean("ΣΑ"), "σα")
  assert_eq(clean("Σ"), "σ")
  assert_eq(clean("ΑΣΑ"), "ασα")
  assert_eq(clean("ΑΣ\u{0301}"), "ας\u{0301}")
  assert_eq(clean("ΑΣ\u{0301}Α"), "ασ\u{0301}α")
  assert_eq(clean("Α\u{0301}Σ"), "α\u{0301}ς")
  assert_eq(clean("ΑΣ1"), "ας")
}

///|
test "trigrams of empty and short text" {
  assert_eq(trigrams(""), [])
  assert_eq(trigrams("!!"), [])
  assert_eq(trigrams("a"), [(" a ", 1)])
  assert_eq(trigrams("ab"), [(" ab", 1), ("ab ", 1)])
}

///|
test "trigrams are counted and sorted by ascending count" {
  assert_eq(trigrams("ab ab"), [("b a", 1), (" ab", 2), ("ab ", 2)])
  assert_eq(trigrams("abc"), [(" ab", 1), ("abc", 1), ("bc ", 1)])
  assert_eq(trigrams("Aa aa! AA"), [("a a", 2), (" aa", 3), ("aa ", 3)])
}

///|
test "trigrams split surrogate pairs like JavaScript slicing" {
  let tuples = trigrams("\u{10428}")
  assert_eq(tuples.length(), 2)
  assert_eq(tuples[0].0.length(), 3)
  assert_eq(tuples[0].0.unsafe_get(1).to_int(), 0xD801)
  assert_eq(tuples[0].0.unsafe_get(2).to_int(), 0xDC28)
  assert_eq(tuples[1].0.unsafe_get(0).to_int(), 0xD801)
  assert_eq(trigrams("\u{10428}\u{10428}").length(), 4)
}

///|
test "lowercase table is sorted" {
  assert_eq(lower_from.length(), lower_to.length())
  for i in 1..<lower_from.length() {
    assert_true(lower_from[i - 1] < lower_from[i])
  }
}
