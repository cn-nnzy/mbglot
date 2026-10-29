///|
/// A language mbglot can identify. Constructors are named after the
/// ISO 639-3 code.
pub(all) enum Lang {
  Spa
  Eng
  Por
  Ind
  Fra
  Deu
  Jav
  Vie
  Ita
  Tur
  Pol
  Swh
  Sun
  Ron
  Hau
  Fuv
  Bos
  Hrv
  Nld
  Srp
  Ckb
  Yor
  Uzn
  Zlm
  Ibo
  Ceb
  Tgl
  Hun
  Azj
  Ces
  Run
  Plt
  Qug
  Mad
  Nya
  Zyb
  Kin
  Zul
  Swe
  Lin
  Som
  Hms
  Hnj
  Ilo
  Rus
  Ukr
  Koi
  Bel
  Bul
  Kaz
  Arb
  Urd
  Pes
  Skr
  Pbu
  Hin
  Mar
  Mai
  Bho
  Npi
  Mag
  Cmn
  Ben
  Jpn
  Kor
  Tel
  Tam
  Guj
  Kan
  Mal
  Mya
  Pan
  Amh
  Tha
  Sin
  Ell
} derive(Eq, Hash, Debug)

///|
let all_langs : FixedArray[Lang] = [
  Spa,
  Eng,
  Por,
  Ind,
  Fra,
  Deu,
  Jav,
  Vie,
  Ita,
  Tur,
  Pol,
  Swh,
  Sun,
  Ron,
  Hau,
  Fuv,
  Bos,
  Hrv,
  Nld,
  Srp,
  Ckb,
  Yor,
  Uzn,
  Zlm,
  Ibo,
  Ceb,
  Tgl,
  Hun,
  Azj,
  Ces,
  Run,
  Plt,
  Qug,
  Mad,
  Nya,
  Zyb,
  Kin,
  Zul,
  Swe,
  Lin,
  Som,
  Hms,
  Hnj,
  Ilo,
  Rus,
  Ukr,
  Koi,
  Bel,
  Bul,
  Kaz,
  Arb,
  Urd,
  Pes,
  Skr,
  Pbu,
  Hin,
  Mar,
  Mai,
  Bho,
  Npi,
  Mag,
  Cmn,
  Ben,
  Jpn,
  Kor,
  Tel,
  Tam,
  Guj,
  Kan,
  Mal,
  Mya,
  Pan,
  Amh,
  Tha,
  Sin,
  Ell,
]

///|
/// Every supported language, in mbglot's fixed order.
pub fn Lang::all() -> Array[Lang] {
  Array::from_fixed_array(all_langs)
}

///|
/// ISO 639-3 code, e.g. `"eng"`.
pub fn Lang::code(self : Lang) -> String {
  match self {
    Spa => "spa"
    Eng => "eng"
    Por => "por"
    Ind => "ind"
    Fra => "fra"
    Deu => "deu"
    Jav => "jav"
    Vie => "vie"
    Ita => "ita"
    Tur => "tur"
    Pol => "pol"
    Swh => "swh"
    Sun => "sun"
    Ron => "ron"
    Hau => "hau"
    Fuv => "fuv"
    Bos => "bos"
    Hrv => "hrv"
    Nld => "nld"
    Srp => "srp"
    Ckb => "ckb"
    Yor => "yor"
    Uzn => "uzn"
    Zlm => "zlm"
    Ibo => "ibo"
    Ceb => "ceb"
    Tgl => "tgl"
    Hun => "hun"
    Azj => "azj"
    Ces => "ces"
    Run => "run"
    Plt => "plt"
    Qug => "qug"
    Mad => "mad"
    Nya => "nya"
    Zyb => "zyb"
    Kin => "kin"
    Zul => "zul"
    Swe => "swe"
    Lin => "lin"
    Som => "som"
    Hms => "hms"
    Hnj => "hnj"
    Ilo => "ilo"
    Rus => "rus"
    Ukr => "ukr"
    Koi => "koi"
    Bel => "bel"
    Bul => "bul"
    Kaz => "kaz"
    Arb => "arb"
    Urd => "urd"
    Pes => "pes"
    Skr => "skr"
    Pbu => "pbu"
    Hin => "hin"
    Mar => "mar"
    Mai => "mai"
    Bho => "bho"
    Npi => "npi"
    Mag => "mag"
    Cmn => "cmn"
    Ben => "ben"
    Jpn => "jpn"
    Kor => "kor"
    Tel => "tel"
    Tam => "tam"
    Guj => "guj"
    Kan => "kan"
    Mal => "mal"
    Mya => "mya"
    Pan => "pan"
    Amh => "amh"
    Tha => "tha"
    Sin => "sin"
    Ell => "ell"
  }
}

///|
/// English name of the language.
pub fn Lang::name(self : Lang) -> String {
  match self {
    Spa => "Spanish"
    Eng => "English"
    Por => "Portuguese"
    Ind => "Indonesian"
    Fra => "French"
    Deu => "German"
    Jav => "Javanese"
    Vie => "Vietnamese"
    Ita => "Italian"
    Tur => "Turkish"
    Pol => "Polish"
    Swh => "Swahili"
    Sun => "Sundanese"
    Ron => "Romanian"
    Hau => "Hausa"
    Fuv => "Nigerian Fulfulde"
    Bos => "Bosnian"
    Hrv => "Croatian"
    Nld => "Dutch"
    Srp => "Serbian"
    Ckb => "Central Kurdish"
    Yor => "Yoruba"
    Uzn => "Northern Uzbek"
    Zlm => "Malay"
    Ibo => "Igbo"
    Ceb => "Cebuano"
    Tgl => "Tagalog"
    Hun => "Hungarian"
    Azj => "North Azerbaijani"
    Ces => "Czech"
    Run => "Rundi"
    Plt => "Plateau Malagasy"
    Qug => "Chimborazo Highland Quichua"
    Mad => "Madurese"
    Nya => "Nyanja"
    Zyb => "Yongbei Zhuang"
    Kin => "Kinyarwanda"
    Zul => "Zulu"
    Swe => "Swedish"
    Lin => "Lingala"
    Som => "Somali"
    Hms => "Southern Qiandong Miao"
    Hnj => "Hmong Njua"
    Ilo => "Iloko"
    Rus => "Russian"
    Ukr => "Ukrainian"
    Koi => "Komi-Permyak"
    Bel => "Belarusian"
    Bul => "Bulgarian"
    Kaz => "Kazakh"
    Arb => "Standard Arabic"
    Urd => "Urdu"
    Pes => "Iranian Persian"
    Skr => "Saraiki"
    Pbu => "Northern Pashto"
    Hin => "Hindi"
    Mar => "Marathi"
    Mai => "Maithili"
    Bho => "Bhojpuri"
    Npi => "Nepali"
    Mag => "Magahi"
    Cmn => "Mandarin Chinese"
    Ben => "Bengali"
    Jpn => "Japanese"
    Kor => "Korean"
    Tel => "Telugu"
    Tam => "Tamil"
    Guj => "Gujarati"
    Kan => "Kannada"
    Mal => "Malayalam"
    Mya => "Burmese"
    Pan => "Panjabi"
    Amh => "Amharic"
    Tha => "Thai"
    Sin => "Sinhala"
    Ell => "Modern Greek"
  }
}

///|
/// Number of speakers in millions, as listed by franc-min 6.2.0 (its
/// readme, from the `speakers` data franc selects languages by). A rough
/// figure for comparing languages, used to break near ties in
/// `Mode::Enhanced`.
pub fn Lang::speakers(self : Lang) -> Int32 {
  match self {
    Spa => 332
    Eng => 322
    Por => 182
    Ind => 140
    Fra => 124
    Deu => 121
    Jav => 76
    Vie => 67
    Ita => 63
    Tur => 59
    Pol => 44
    Swh => 30
    Sun => 27
    Ron => 26
    Hau => 22
    Fuv => 22
    Bos => 21
    Hrv => 21
    Nld => 21
    Srp => 21
    Ckb => 20
    Yor => 20
    Uzn => 18
    Zlm => 18
    Ibo => 17
    Ceb => 15
    Tgl => 15
    Hun => 15
    Azj => 14
    Ces => 12
    Run => 11
    Plt => 10
    Qug => 10
    Mad => 10
    Nya => 10
    Zyb => 10
    Kin => 9
    Zul => 9
    Swe => 9
    Lin => 8
    Som => 8
    Hms => 8
    Hnj => 8
    Ilo => 8
    Rus => 288
    Ukr => 41
    Koi => 13
    Bel => 10
    Bul => 9
    Kaz => 8
    Arb => 280
    Urd => 54
    Pes => 33
    Skr => 15
    Pbu => 10
    Hin => 182
    Mar => 65
    Mai => 35
    Bho => 25
    Npi => 16
    Mag => 11
    Cmn => 885
    Ben => 196
    Jpn => 125
    Kor => 75
    Tel => 73
    Tam => 62
    Guj => 44
    Kan => 38
    Mal => 34
    Mya => 31
    Pan => 26
    Amh => 23
    Tha => 21
    Sin => 13
    Ell => 12
  }
}

///|
/// Looks up a language by ISO 639-3 code. Matching ignores ASCII case.
pub fn Lang::from_code(code : String) -> Lang? {
  match code.to_lower() {
    "spa" => Some(Spa)
    "eng" => Some(Eng)
    "por" => Some(Por)
    "ind" => Some(Ind)
    "fra" => Some(Fra)
    "deu" => Some(Deu)
    "jav" => Some(Jav)
    "vie" => Some(Vie)
    "ita" => Some(Ita)
    "tur" => Some(Tur)
    "pol" => Some(Pol)
    "swh" => Some(Swh)
    "sun" => Some(Sun)
    "ron" => Some(Ron)
    "hau" => Some(Hau)
    "fuv" => Some(Fuv)
    "bos" => Some(Bos)
    "hrv" => Some(Hrv)
    "nld" => Some(Nld)
    "srp" => Some(Srp)
    "ckb" => Some(Ckb)
    "yor" => Some(Yor)
    "uzn" => Some(Uzn)
    "zlm" => Some(Zlm)
    "ibo" => Some(Ibo)
    "ceb" => Some(Ceb)
    "tgl" => Some(Tgl)
    "hun" => Some(Hun)
    "azj" => Some(Azj)
    "ces" => Some(Ces)
    "run" => Some(Run)
    "plt" => Some(Plt)
    "qug" => Some(Qug)
    "mad" => Some(Mad)
    "nya" => Some(Nya)
    "zyb" => Some(Zyb)
    "kin" => Some(Kin)
    "zul" => Some(Zul)
    "swe" => Some(Swe)
    "lin" => Some(Lin)
    "som" => Some(Som)
    "hms" => Some(Hms)
    "hnj" => Some(Hnj)
    "ilo" => Some(Ilo)
    "rus" => Some(Rus)
    "ukr" => Some(Ukr)
    "koi" => Some(Koi)
    "bel" => Some(Bel)
    "bul" => Some(Bul)
    "kaz" => Some(Kaz)
    "arb" => Some(Arb)
    "urd" => Some(Urd)
    "pes" => Some(Pes)
    "skr" => Some(Skr)
    "pbu" => Some(Pbu)
    "hin" => Some(Hin)
    "mar" => Some(Mar)
    "mai" => Some(Mai)
    "bho" => Some(Bho)
    "npi" => Some(Npi)
    "mag" => Some(Mag)
    "cmn" => Some(Cmn)
    "ben" => Some(Ben)
    "jpn" => Some(Jpn)
    "kor" => Some(Kor)
    "tel" => Some(Tel)
    "tam" => Some(Tam)
    "guj" => Some(Guj)
    "kan" => Some(Kan)
    "mal" => Some(Mal)
    "mya" => Some(Mya)
    "pan" => Some(Pan)
    "amh" => Some(Amh)
    "tha" => Some(Tha)
    "sin" => Some(Sin)
    "ell" => Some(Ell)
    _ => None
  }
}

///|
/// Writes the ISO 639-3 code.
pub impl Show for Lang with fn output(self, logger) {
  logger.write_string(self.code())
}
