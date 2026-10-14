///|
fn lang_of(text : String, options? : @mbglot.Options) -> @mbglot.Lang? {
  let detection = match options {
    Some(o) => @mbglot.detect(text, options=o)
    None => @mbglot.detect(text)
  }
  detection.map(d => d.lang)
}

///|
test "a stray kana does not make Chinese text Japanese" {
  // A brand name with の in a Chinese sentence.
  let text = "我们公司的产品在“美味の店”有售，欢迎大家来购买。"
  let franc = @mbglot.Options::new(mode=Franc)
  assert_eq(lang_of(text, options=franc), Some(@mbglot.Jpn))
  assert_eq(lang_of(text), Some(@mbglot.Cmn))
  assert_eq(@mbglot.detect(text).map(d => d.script), Some(@mbglot.Han))
}

///|
test "Japanese stays Japanese" {
  assert_eq(
    lang_of(
      "いつもお世話になっております。請求書の宛名を変更できますか。",
    ),
    Some(@mbglot.Jpn),
  )
  // Mostly kanji, but kana well above a tenth of the CJK characters.
  assert_eq(lang_of("東京大学の学生と先生です"), Some(@mbglot.Jpn))
}

///|
test "Korean with hanja is Korean" {
  // Hanja for 大韓民國 and 憲法 inside Korean text.
  let text = "大韓民國 憲法 第一條 대한민국은 民主共和國이다"
  let franc = @mbglot.Options::new(mode=Franc)
  assert_eq(lang_of(text, options=franc), Some(@mbglot.Cmn))
  assert_eq(lang_of(text), Some(@mbglot.Kor))
  assert_eq(@mbglot.detect(text).map(d => d.script), Some(@mbglot.Hangul))
}

///|
test "options can rule the refinement out" {
  let text = "大韓民國 憲法 第一條 대한민국은 民主共和國이다"
  let no_korean = @mbglot.Options::new(deny=[@mbglot.Kor])
  assert_eq(lang_of(text, options=no_korean), Some(@mbglot.Cmn))
  let chinese_text = "我们公司的产品在“美味の店”有售，欢迎大家来购买。"
  let japanese_only = @mbglot.Options::new(allow=[@mbglot.Jpn])
  assert_eq(lang_of(chinese_text, options=japanese_only), Some(@mbglot.Jpn))
}

///|
test "simplified and traditional Chinese" {
  assert_eq(
    @mbglot.chinese_variant("我们这个国家的发展很快。"),
    Some(@mbglot.Simplified),
  )
  assert_eq(
    @mbglot.chinese_variant("我們這個國家的發展很快。"),
    Some(@mbglot.Traditional),
  )
  // Characters common to both standards, and no Chinese at all.
  assert_eq(
    @mbglot.chinese_variant("我的朋友在大学"),
    Some(@mbglot.Simplified),
  )
  assert_eq(@mbglot.chinese_variant("我的朋友"), None)
  assert_eq(@mbglot.chinese_variant("hello"), None)
  // As many of each.
  assert_eq(@mbglot.chinese_variant("这這"), None)
}

///|
test "segments keep Korean with hanja in one piece" {
  let text = "大韓民國 憲法 第一條 대한민국은 民主共和國이다. Hello, this part of the text is written in English."
  let result = @mbglot.segments(text)
  assert_eq(result.map(s => s.detection.map(d => d.lang)), [
    Some(@mbglot.Kor),
    Some(@mbglot.Eng),
  ])
}
