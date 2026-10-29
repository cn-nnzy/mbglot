///|
/// The ISO 639-1 two-letter code for the language. A language that ISO
/// 639-3 counts as the main member of a macrolanguage gets the
/// macrolanguage's code, as it is commonly tagged: Mandarin `zh`, Standard
/// Arabic `ar`, Iranian Persian `fa`, Malay `ms`, Northern Uzbek `uz`,
/// North Azerbaijani `az`, Plateau Malagasy `mg`, Swahili `sw`, Northern
/// Pashto `ps` and Nepali `ne`. `None` for languages without one, such as
/// Cebuano or Bhojpuri, and for members that are not the main form of
/// their macrolanguage, such as Nigerian Fulfulde (`ff`) or Central
/// Kurdish (`ku`).
pub fn Lang::iso639_1(self : Lang) -> String? {
  let code = match self {
    Spa => "es"
    Eng => "en"
    Por => "pt"
    Ind => "id"
    Fra => "fr"
    Deu => "de"
    Jav => "jv"
    Vie => "vi"
    Ita => "it"
    Tur => "tr"
    Pol => "pl"
    Swh => "sw"
    Sun => "su"
    Ron => "ro"
    Hau => "ha"
    Bos => "bs"
    Hrv => "hr"
    Nld => "nl"
    Srp => "sr"
    Yor => "yo"
    Uzn => "uz"
    Zlm => "ms"
    Ibo => "ig"
    Tgl => "tl"
    Hun => "hu"
    Azj => "az"
    Ces => "cs"
    Run => "rn"
    Plt => "mg"
    Nya => "ny"
    Kin => "rw"
    Zul => "zu"
    Swe => "sv"
    Lin => "ln"
    Som => "so"
    Rus => "ru"
    Ukr => "uk"
    Bel => "be"
    Bul => "bg"
    Kaz => "kk"
    Arb => "ar"
    Urd => "ur"
    Pes => "fa"
    Pbu => "ps"
    Hin => "hi"
    Mar => "mr"
    Npi => "ne"
    Cmn => "zh"
    Ben => "bn"
    Jpn => "ja"
    Kor => "ko"
    Tel => "te"
    Tam => "ta"
    Guj => "gu"
    Kan => "kn"
    Mal => "ml"
    Mya => "my"
    Pan => "pa"
    Amh => "am"
    Tha => "th"
    Sin => "si"
    Ell => "el"
    Fuv
    | Ckb
    | Ceb
    | Qug
    | Mad
    | Zyb
    | Hms
    | Hnj
    | Ilo
    | Koi
    | Skr
    | Mai
    | Bho
    | Mag => return None
  }
  Some(code)
}

///|
/// A BCP 47 language tag for the language: its ISO 639-1 code (see
/// `iso639_1`) when it has one, otherwise its ISO 639-3 code. Both are
/// valid primary language subtags.
pub fn Lang::bcp47(self : Lang) -> String {
  self.iso639_1().unwrap_or(self.code())
}

///|
/// Macrolanguages whose main member is supported, by their ISO 639-1 and
/// ISO 639-3 codes.
let macrolanguages : Array[(String, Lang)] = [
  ("zh", Cmn),
  ("zho", Cmn),
  ("ar", Arb),
  ("ara", Arb),
  ("fa", Pes),
  ("fas", Pes),
  ("ms", Zlm),
  ("msa", Zlm),
  ("uz", Uzn),
  ("uzb", Uzn),
  ("az", Azj),
  ("aze", Azj),
  ("mg", Plt),
  ("mlg", Plt),
  ("sw", Swh),
  ("swa", Swh),
  ("ps", Pbu),
  ("pus", Pbu),
  ("ne", Npi),
  ("nep", Npi),
]

///|
/// ISO 639-2/B codes and other codes still in use that name a supported
/// language. Filipino is standardised Tagalog; `in` is the withdrawn code
/// for Indonesian that some systems still send.
let other_codes : Array[(String, Lang)] = [
  ("chi", Cmn),
  ("per", Pes),
  ("may", Zlm),
  ("fre", Fra),
  ("ger", Deu),
  ("dut", Nld),
  ("cze", Ces),
  ("rum", Ron),
  ("gre", Ell),
  ("bur", Mya),
  ("fil", Tgl),
  ("in", Ind),
]

///|
fn is_letters(s : StringView) -> Bool {
  s.iter().all(c => c >= 'a' && c <= 'z')
}

///|
/// The language of a BCP 47 tag such as `pt-BR`, `zh-Hant-TW`, `sr-Latn`
/// or `es_419`, from its primary language subtag, matched without regard
/// to ASCII case: ISO 639-1 codes (see `iso639_1`), ISO 639-3 codes (see
/// `code`), the macrolanguages named in `iso639_1`, and ISO 639-2/B codes
/// such as `ger`. After a macrolanguage, an extended language subtag
/// decides instead (`zh-cmn` is Mandarin, `zh-yue` Cantonese and so
/// `None`). Script, region and other subtags are ignored, and `_` is
/// accepted as a separator. `None` for other languages, including
/// macrolanguages whose main member is not supported (`ku`, `ff`), and for
/// malformed tags.
pub fn Lang::from_bcp47(tag : String) -> Lang? {
  let subtags = tag
    .to_lower()
    .replace_all(old="_", new="-")
    .split("-")
    .collect()
  let primary = subtags[0].to_owned()
  if primary.length() < 2 || primary.length() > 3 || !is_letters(primary) {
    return None
  }
  if macrolanguages.search_by(e => e.0 == primary) is Some(i) {
    if subtags.length() > 1 &&
      subtags[1].length() == 3 &&
      is_letters(subtags[1]) {
      return Lang::from_code(subtags[1].to_owned())
    }
    return Some(macrolanguages[i].1)
  }
  if primary.length() == 3 && Lang::from_code(primary) is Some(lang) {
    return Some(lang)
  }
  for lang in all_langs {
    if lang.iso639_1() is Some(code) && code == primary {
      return Some(lang)
    }
  }
  match other_codes.search_by(e => e.0 == primary) {
    Some(i) => Some(other_codes[i].1)
    None => None
  }
}

///|
/// The name of the language in the language itself (its endonym). These
/// were written for mbglot; where a language has several common names,
/// the more widely used one is given.
pub fn Lang::native_name(self : Lang) -> String {
  match self {
    Spa => "español"
    Eng => "English"
    Por => "português"
    Ind => "Bahasa Indonesia"
    Fra => "français"
    Deu => "Deutsch"
    Jav => "Basa Jawa"
    Vie => "Tiếng Việt"
    Ita => "italiano"
    Tur => "Türkçe"
    Pol => "polski"
    Swh => "Kiswahili"
    Sun => "Basa Sunda"
    Ron => "română"
    Hau => "Hausa"
    Fuv => "Fulfulde"
    Bos => "bosanski"
    Hrv => "hrvatski"
    Nld => "Nederlands"
    Srp => "српски"
    Ckb => "کوردی"
    Yor => "Yorùbá"
    Uzn => "oʻzbekcha"
    Zlm => "Bahasa Melayu"
    Ibo => "Igbo"
    Ceb => "Sinugbuanong Binisayâ"
    Tgl => "Tagalog"
    Hun => "magyar"
    Azj => "azərbaycanca"
    Ces => "čeština"
    Run => "Ikirundi"
    Plt => "Malagasy"
    Qug => "Kichwa"
    Mad => "Basa Madhura"
    Nya => "Chichewa"
    Zyb => "Vahcuengh"
    Kin => "Ikinyarwanda"
    Zul => "isiZulu"
    Swe => "svenska"
    Lin => "lingála"
    Som => "Soomaali"
    Hms => "Hmub"
    Hnj => "Hmoob Ntsuab"
    Ilo => "Ilokano"
    Rus => "русский"
    Ukr => "українська"
    Koi => "перем коми"
    Bel => "беларуская"
    Bul => "български"
    Kaz => "қазақ тілі"
    Arb => "العربية"
    Urd => "اردو"
    Pes => "فارسی"
    Skr => "سرائیکی"
    Pbu => "پښتو"
    Hin => "हिन्दी"
    Mar => "मराठी"
    Mai => "मैथिली"
    Bho => "भोजपुरी"
    Npi => "नेपाली"
    Mag => "मगही"
    Cmn => "中文"
    Ben => "বাংলা"
    Jpn => "日本語"
    Kor => "한국어"
    Tel => "తెలుగు"
    Tam => "தமிழ்"
    Guj => "ગુજરાતી"
    Kan => "ಕನ್ನಡ"
    Mal => "മലയാളം"
    Mya => "မြန်မာဘာသာ"
    Pan => "ਪੰਜਾਬੀ"
    Amh => "አማርኛ"
    Tha => "ไทย"
    Sin => "සිංහල"
    Ell => "Ελληνικά"
  }
}
