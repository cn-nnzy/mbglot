///|
fn repeat(s : String, n : Int) -> String {
  let b = StringBuilder()
  for _ in 0..<n {
    b.write_string(s)
  }
  b.to_string()
}

///|
fn lone_surrogate(unit : Int) -> String {
  let b = StringBuilder()
  b.write_char(unit.unsafe_to_char())
  b.to_string()
}

///|
test "no script in empty or symbol-only text" {
  assert_eq(@mbglot.detect_script(""), None)
  assert_eq(@mbglot.detect_script("   \t\n "), None)
  assert_eq(@mbglot.detect_script("0123456789"), None)
  assert_eq(@mbglot.detect_script("!?.,;:-()[]{}\"'@#%&*+=/\\"), None)
  assert_eq(@mbglot.detect_script("😀🎉👍🏽❤️"), None)
  assert_eq(@mbglot.detect_script("١٢٣"), Some(@mbglot.Arabic))
}

///|
test "single scripts" {
  assert_eq(@mbglot.detect_script("Hello, world"), Some(@mbglot.Latin))
  assert_eq(
    @mbglot.detect_script("Привет, мир"),
    Some(@mbglot.Cyrillic),
  )
  assert_eq(
    @mbglot.detect_script("مرحبا بالعالم"),
    Some(@mbglot.Arabic),
  )
  assert_eq(
    @mbglot.detect_script("नमस्ते दुनिया"),
    Some(@mbglot.Devanagari),
  )
  assert_eq(@mbglot.detect_script("你好，世界"), Some(@mbglot.Han))
  assert_eq(@mbglot.detect_script("こんにちは"), Some(@mbglot.Kana))
  assert_eq(@mbglot.detect_script("안녕하세요"), Some(@mbglot.Hangul))
  assert_eq(@mbglot.detect_script("হ্যালো"), Some(@mbglot.Bengali))
  assert_eq(@mbglot.detect_script("ꦲꦭꦺꦴ"), Some(@mbglot.Javanese))
  assert_eq(
    @mbglot.detect_script("నమస్కారం"),
    Some(@mbglot.Telugu),
  )
  assert_eq(@mbglot.detect_script("வணக்கம்"), Some(@mbglot.Tamil))
  assert_eq(@mbglot.detect_script("નમસ્તે"), Some(@mbglot.Gujarati))
  assert_eq(
    @mbglot.detect_script("ನಮಸ್ಕಾರ"),
    Some(@mbglot.Kannada),
  )
  assert_eq(
    @mbglot.detect_script("നമസ്കാരം"),
    Some(@mbglot.Malayalam),
  )
  assert_eq(
    @mbglot.detect_script("မင်္ဂလာပါ"),
    Some(@mbglot.Myanmar),
  )
  assert_eq(
    @mbglot.detect_script("ਸਤ ਸ੍ਰੀ ਅਕਾਲ"),
    Some(@mbglot.Gurmukhi),
  )
  assert_eq(@mbglot.detect_script("ሰላም"), Some(@mbglot.Ethiopic))
  assert_eq(@mbglot.detect_script("สวัสดี"), Some(@mbglot.Thai))
  assert_eq(
    @mbglot.detect_script("ආයුබෝවන්"),
    Some(@mbglot.Sinhala),
  )
  assert_eq(@mbglot.detect_script("Γειά σου"), Some(@mbglot.Greek))
}

///|
test "mixed scripts take the majority" {
  assert_eq(@mbglot.detect_script("Hello мир"), Some(@mbglot.Latin))
  assert_eq(@mbglot.detect_script("Привет world"), Some(@mbglot.Cyrillic))
  assert_eq(
    @mbglot.detect_script("Order #4471 — заказ не пришёл"),
    Some(@mbglot.Cyrillic),
  )
}

///|
test "ties go to the script listed first, not the one seen first" {
  assert_eq(@mbglot.detect_script("ab вг"), Some(@mbglot.Latin))
  assert_eq(@mbglot.detect_script("вг ab"), Some(@mbglot.Latin))
  assert_eq(@mbglot.detect_script("αβ вг"), Some(@mbglot.Cyrillic))
}

///|
test "Han ideographs count for both Han and Kana" {
  assert_eq(@mbglot.detect_script("日本語"), Some(@mbglot.Han))
  assert_eq(@mbglot.detect_script("日本語を話す"), Some(@mbglot.Kana))
  assert_eq(@mbglot.detect_script("カタカナ"), Some(@mbglot.Kana))
}

///|
test "combining marks belong to no script outside their block" {
  assert_eq(@mbglot.detect_script("\u{0301}\u{0308}"), None)
  assert_eq(@mbglot.detect_script("e\u{0301}"), Some(@mbglot.Latin))
  assert_eq(@mbglot.detect_script("а\u{0301}"), Some(@mbglot.Cyrillic))
  assert_eq(@mbglot.detect_script("\u{0483}"), Some(@mbglot.Cyrillic))
}

///|
test "surrogate pairs are decoded" {
  assert_eq(@mbglot.detect_script("\u{20000}\u{2A6DF}"), Some(@mbglot.Han))
  assert_eq(@mbglot.detect_script("\u{1EE00}"), Some(@mbglot.Arabic))
  assert_eq(@mbglot.detect_script("\u{1B000}"), Some(@mbglot.Kana))
  assert_eq(@mbglot.detect_script("\u{10140}"), Some(@mbglot.Greek))
  assert_eq(@mbglot.detect_script("\u{1F200}"), Some(@mbglot.Kana))
  assert_eq(@mbglot.detect_script("\u{1F600}"), None)
}

///|
test "unpaired surrogates belong to no script" {
  let high = lone_surrogate(0xD840)
  let low = lone_surrogate(0xDC00)
  assert_eq(high.length(), 1)
  assert_eq(@mbglot.detect_script(high), None)
  assert_eq(@mbglot.detect_script(low), None)
  assert_eq(@mbglot.detect_script(high + "a"), Some(@mbglot.Latin))
  assert_eq(@mbglot.detect_script(low + high), None)
}

///|
test "only the first 2048 code units are sampled" {
  let text = repeat("a", 2000) + repeat("б", 3000)
  assert_eq(@mbglot.detect_script(text), Some(@mbglot.Latin))
  assert_eq(@mbglot.detect_script(repeat(" ", 2048) + "abc"), None)
  assert_eq(@mbglot.detect_script(repeat(" ", 2047) + "a"), Some(@mbglot.Latin))
}

///|
test "a surrogate pair cut by the sample limit is ignored" {
  assert_eq(
    @mbglot.detect_script(repeat(" ", 2046) + "\u{20000}"),
    Some(@mbglot.Han),
  )
  assert_eq(@mbglot.detect_script(repeat(" ", 2047) + "\u{20000}"), None)
}
