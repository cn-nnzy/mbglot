///|
/// A writing system as franc-min distinguishes them. `Kana` covers
/// Hiragana and Katakana together with the Han ideographs used in
/// Japanese text.
pub(all) enum Script {
  Han
  Latin
  Cyrillic
  Arabic
  Bengali
  Devanagari
  Kana
  Javanese
  Hangul
  Telugu
  Tamil
  Gujarati
  Kannada
  Malayalam
  Myanmar
  Gurmukhi
  Ethiopic
  Thai
  Sinhala
  Greek
} derive(Eq, Hash, Debug)

///|
let all_scripts : FixedArray[Script] = [
  Han,
  Latin,
  Cyrillic,
  Arabic,
  Bengali,
  Devanagari,
  Kana,
  Javanese,
  Hangul,
  Telugu,
  Tamil,
  Gujarati,
  Kannada,
  Malayalam,
  Myanmar,
  Gurmukhi,
  Ethiopic,
  Thai,
  Sinhala,
  Greek,
]

///|
/// Every supported script, in mbglot's fixed order.
pub fn Script::all() -> Array[Script] {
  Array::from_fixed_array(all_scripts)
}

///|
/// English name of the script.
pub fn Script::name(self : Script) -> String {
  match self {
    Han => "Han"
    Latin => "Latin"
    Cyrillic => "Cyrillic"
    Arabic => "Arabic"
    Bengali => "Bengali"
    Devanagari => "Devanagari"
    Kana => "Kana"
    Javanese => "Javanese"
    Hangul => "Hangul"
    Telugu => "Telugu"
    Tamil => "Tamil"
    Gujarati => "Gujarati"
    Kannada => "Kannada"
    Malayalam => "Malayalam"
    Myanmar => "Myanmar"
    Gurmukhi => "Gurmukhi"
    Ethiopic => "Ethiopic"
    Thai => "Thai"
    Sinhala => "Sinhala"
    Greek => "Greek"
  }
}

///|
/// Writes the script name.
pub impl Show for Script with fn output(self, logger) {
  logger.write_string(self.name())
}
