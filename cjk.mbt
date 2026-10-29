///|
/// Which standard of written Chinese a text uses.
pub(all) enum ChineseVariant {
  /// Simplified characters, as in mainland China and Singapore.
  Simplified
  /// Traditional characters, as in Taiwan, Hong Kong and Macau.
  Traditional
} derive(Eq, Debug)

///|
/// Common characters that differ between the standards: the simplified
/// form of each character at the same position as its traditional form.
/// Pairs where the simplified form is also an ordinary traditional
/// character (后, 里, 面, 干, 台, 只, 几, 云, 系) are left out.
let simplified_forms : String = "们这个说时国会来对发么东过还没为学问间见买卖长车门开关电话语认识让请谢吗现实点经动头进种样应机体业从两边无产务气万与并处号写报场书华难张军声观历钱银铁网视读听记饭馆鱼鸟马红绿蓝级结给线练习爱欢乐岁节图讲试题错医药区县广厂价钟简单复杂离远运将爷妈儿孙亲戏汉"

///|
let traditional_forms : String = "們這個說時國會來對發麼東過還沒為學問間見買賣長車門開關電話語認識讓請謝嗎現實點經動頭進種樣應機體業從兩邊無產務氣萬與並處號寫報場書華難張軍聲觀歷錢銀鐵網視讀聽記飯館魚鳥馬紅綠藍級結給線練習愛歡樂歲節圖講試題錯醫藥區縣廣廠價鐘簡單復雜離遠運將爺媽兒孫親戲漢"

///|
/// Whether Chinese `text` is written in simplified or traditional
/// characters, judged by about 120 common characters that differ between
/// the two. `None` when the text has none of them, or as many of each.
/// This is a hint: it does not check that the text is Chinese, and
/// Japanese kanji often match neither or both lists.
pub fn chinese_variant(text : String) -> ChineseVariant? {
  let mut simplified = 0
  let mut traditional = 0
  for ch in text {
    if simplified_forms.contains_char(ch) {
      simplified += 1
    } else if traditional_forms.contains_char(ch) {
      traditional += 1
    }
  }
  if simplified > traditional {
    Some(Simplified)
  } else if traditional > simplified {
    Some(Traditional)
  } else {
    None
  }
}

///|
fn script_index(script : Script) -> Int32 {
  for i, s in all_scripts {
    if s == script {
      return i
    }
  }
  -1
}

///|
/// Minimum share of kana among the kana and Han characters of a text for
/// it to be Japanese. Japanese prose is usually 30% to 70% kana; Chinese
/// text may contain a stray kana such as の in a brand name.
let min_kana_share : Double = 0.1

///|
/// Minimum share of Hangul among the Hangul and Han characters of a text
/// for it to be Korean. Korean that mixes in hanja is still mostly Hangul.
let min_hangul_share : Double = 0.2

///|
/// franc's result for a text in Han or kana, refined: franc calls a text
/// Japanese as soon as it has one kana more than it has Han characters'
/// worth of other letters, and Chinese when Han outnumbers Hangul. A text
/// whose kana are under `min_kana_share` of its CJK characters is Chinese,
/// and one whose Hangul reaches `min_hangul_share` is Korean. Languages
/// the options exclude are not chosen.
fn refine_cjk(
  stats : TextStats,
  script : Script,
  ranked : Array[(Lang, Double)],
  allow : Array[Lang],
  deny : Array[Lang],
) -> (Script, Array[(Lang, Double)]) {
  if script != Han && script != Kana {
    return (script, ranked)
  }
  let counts = stats.scripts
  let han = counts[script_index(Han)]
  // Han ideographs also count as kana; the difference is kana proper.
  let kana = counts[script_index(Kana)] - han
  let hangul = counts[script_index(Hangul)]
  if hangul > 0 &&
    hangul.to_double() >= min_hangul_share * (hangul + han).to_double() &&
    allowed(Kor, allow, deny) {
    return (Hangul, [(Kor, 1.0)])
  }
  if script == Kana &&
    kana.to_double() < min_kana_share * (kana + han).to_double() &&
    allowed(Cmn, allow, deny) {
    return (Han, [(Cmn, 1.0)])
  }
  (script, ranked)
}
