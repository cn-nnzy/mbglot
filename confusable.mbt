///|
/// How `detect` and `rank` decide between languages.
pub(all) enum Mode {
  /// franc-min 6.2.0's trigram ranking alone, without markup removal: the
  /// same languages and scores as franc.
  Franc
  /// Markup removal, then franc's ranking, then a second pass that settles
  /// closely related languages by their letters and common words. The
  /// default.
  Enhanced
} derive(Eq, Debug)

///|
/// Languages that franc's trigrams often mix up, with the evidence that
/// tells them apart. `markers` are letters or letter sequences, each with
/// the language it points to and a weight per occurrence; `words` are
/// common words (lowercase) that each count once per occurrence.
priv struct Group {
  langs : Array[Lang]
  markers : Array[(Lang, String, Int)]
  words : Array[(Lang, Array[String])]
}

///|
let groups : Array[Group] = [
  {
    langs: [Spa, Por],
    markers: [
      (Spa, "ñ", 3),
      (Spa, "¿", 3),
      (Spa, "¡", 3),
      (Por, "ã", 3),
      (Por, "õ", 3),
      (Por, "ç", 3),
      (Por, "ê", 2),
      (Por, "ô", 2),
      (Por, "â", 2),
      (Por, "à", 1),
      (Por, "lh", 2),
      (Por, "nh", 2),
    ],
    words: [
      (
        Spa,
        [
          "el", "los", "las", "del", "y", "es", "una", "pero", "muy", "yo", "tengo",
          "hay", "está", "estoy", "lo", "su", "sus", "al", "ella", "él", "usted",
          "qué", "cómo", "eso", "esto", "nunca", "puedo", "quiero", "también",
          "ahora",
        ],
      ),
      (
        Por,
        [
          "o", "os", "do", "da", "dos", "das", "e", "é", "um", "uma", "não", "em",
          "no", "na", "com", "você", "eu", "muito", "mas", "isso", "isto", "ele",
          "ela", "seu", "sua", "tenho", "há", "estou", "nunca", "posso", "quero",
          "também", "agora", "pelo", "pela",
        ],
      ),
    ],
  },
  {
    langs: [Rus, Ukr, Bel, Bul, Srp, Kaz],
    markers: [
      (Rus, "ы", 2),
      (Rus, "э", 2),
      (Rus, "ё", 2),
      (Bel, "ы", 1),
      (Bel, "э", 1),
      (Bel, "ў", 4),
      (Bel, "і", 1),
      (Bel, "дз", 1),
      (Bel, "ць", 1),
      (Ukr, "і", 1),
      (Ukr, "ї", 3),
      (Ukr, "є", 3),
      (Ukr, "ґ", 3),
      (Bul, "ъ", 1),
      (Srp, "ђ", 4),
      (Srp, "ј", 4),
      (Srp, "љ", 4),
      (Srp, "њ", 4),
      (Srp, "ћ", 4),
      (Srp, "џ", 4),
      (Kaz, "ә", 4),
      (Kaz, "ғ", 4),
      (Kaz, "қ", 4),
      (Kaz, "ң", 4),
      (Kaz, "ө", 4),
      (Kaz, "ұ", 4),
      (Kaz, "ү", 4),
      (Kaz, "һ", 2),
    ],
    words: [
      (
        Rus,
        [
          "что", "это", "он", "она", "мы", "вы", "они", "есть",
          "нет", "был", "была", "было", "очень", "только",
          "меня", "тебя", "его", "её", "уже", "когда", "если",
          "я", "мне", "так", "здесь", "сейчас", "почему",
          "хочу",
        ],
      ),
      (
        Ukr,
        [
          "що", "це", "він", "вона", "ми", "ви", "вони", "є",
          "немає", "був", "була", "дуже", "тільки", "мене",
          "тебе", "його", "вже", "коли", "якщо", "мені", "так",
          "тут", "зараз", "чому", "хочу", "та", "й", "до",
        ],
      ),
      (
        Bel,
        [
          "што", "гэта", "ён", "яна", "мы", "вы", "яны", "ёсць",
          "няма", "быў", "вельмі", "толькі", "мяне", "цябе",
          "яго", "ужо", "калі", "мне", "і", "у",
        ],
      ),
      (
        Bul,
        [
          "е", "са", "съм", "си", "сме", "сте", "ще", "това",
          "този", "тази", "какво", "който", "която", "той",
          "тя", "ние", "вие", "те", "от", "много", "само", "мен",
          "теб", "него", "вече", "когато", "ако", "тук", "сега",
          "защо", "искам", "не", "се", "да",
        ],
      ),
      (
        Srp,
        [
          "је", "су", "сам", "си", "смо", "сте", "ће", "ово",
          "шта", "што", "ко", "који", "она", "он", "ми", "ви",
          "они", "од", "много", "само", "мене", "тебе", "њега",
          "већ", "када", "ако", "овде", "сада", "зашто", "хоћу",
        ],
      ),
    ],
  },
  {
    langs: [Hrv, Srp, Bos],
    markers: [],
    words: [
      (
        Hrv,
        [
          "tko", "što", "tijekom", "također", "tisuću", "tisuće", "kruh", "glazba",
          "sveučilište", "zrakoplov", "kazalište", "vlak", "kava", "jesi", "jeste",
          "lijepo", "mlijeko", "rijeka", "vrijeme", "dijete", "htio", "htjela", "gdje",
          "uvijek", "nisam", "tjedan", "siječanj", "kolovoz", "obitelj", "zrak",
          "povijest", "bok", "hvala", "molim", "kćer", "kći",
        ],
      ),
      (
        Srp,
        [
          "ko", "šta", "tokom", "takođe", "hiljadu", "hiljade", "hleb", "muzika",
          "univerzitet", "avion", "pozorište", "voz", "kafa", "lepo", "mleko", "reka",
          "vreme", "dete", "hteo", "htela", "gde", "uvek", "nedelja", "nedelju",
          "porodica", "vazduh", "istorija", "hoću", "lep", "lepa", "devojka", "pevati",
          "videti", "voleti", "razumem", "ćerka", "beše",
        ],
      ),
      (
        Bos,
        [
          "ko", "šta", "tokom", "također", "hiljadu", "hiljade", "hljeb", "muzika",
          "univerzitet", "avion", "pozorište", "voz", "kahva", "kafa", "lijepo",
          "mlijeko", "rijeka", "vrijeme", "dijete", "htio", "htjela", "gdje", "uvijek",
          "sedmica", "sedmicu", "porodica", "zrak", "historija", "lahko", "mehko",
          "hoću", "hvala", "ćerka", "ahbab",
        ],
      ),
    ],
  },
  {
    langs: [Ind, Zlm],
    markers: [],
    words: [
      (
        Ind,
        [
          "bisa", "uang", "karena", "kamu", "anda", "nggak", "gak", "enggak", "aja",
          "kantor", "mobil", "sepeda", "dong", "banget", "sih", "kok", "lagi", "belum",
          "sekali", "cewek", "cowok", "kalian", "mereka", "terima", "mau", "pergi",
          "bagaimana", "kenapa", "apakah", "sangat", "tahu", "teman", "dia", "bukan",
        ],
      ),
      (
        Zlm,
        [
          "boleh", "wang", "kerana", "awak", "tak", "nak", "sahaja", "pejabat", "kereta",
          "basikal", "encik", "bilik", "hendak", "beliau", "kawan", "tahu", "mengapa",
          "bagaimanakah", "adakah", "amat", "sangat", "ingin", "pergi", "dia", "bukan",
          "mahu", "saya", "kamu", "anda", "mereka", "telefon", "universiti", "sekolah",
        ],
      ),
    ],
  },
  {
    langs: [Run, Kin],
    markers: [(Kin, "cy", 2), (Kin, "jy", 2), (Kin, "shy", 2), (Run, "vy", 2)],
    words: [
      (
        Kin,
        ["ni", "cyane", "ibyo", "byose", "nta", "uyu", "ubu", "iki", "kandi"],
      ),
      (
        Run,
        ["ni", "cane", "ivyo", "vyose", "nta", "uyu", "ubu", "ico", "kandi"],
      ),
    ],
  },
  {
    langs: [Tgl, Ceb],
    markers: [],
    words: [
      (
        Tgl,
        [
          "ng", "hindi", "ito", "iyan", "iyon", "ay", "po", "niya", "ko", "mo", "kayo",
          "akin", "kanya", "bakit", "paano", "saan", "may", "lang", "din", "rin",
          "ba", "talaga",
        ],
      ),
      (
        Ceb,
        [
          "ug", "og", "dili", "kini", "kana", "unsa", "ngano", "naa", "kaayo", "nga",
          "imong", "akong", "nimo", "niini", "adto", "diha", "asa", "lang", "pud",
          "sad", "gyud", "ba",
        ],
      ),
    ],
  },
  {
    langs: [Arb, Pes, Urd, Skr, Ckb, Pbu],
    markers: [
      (Arb, "ة", 2),
      (Arb, "ي", 1),
      (Arb, "ك", 1),
      (Arb, "ى", 1),
      (Ckb, "ڕ", 3),
      (Ckb, "ڵ", 3),
      (Ckb, "ۆ", 3),
      (Ckb, "ێ", 3),
      (Ckb, "ە", 3),
      (Pbu, "ټ", 3),
      (Pbu, "ډ", 3),
      (Pbu, "ړ", 3),
      (Pbu, "ږ", 3),
      (Pbu, "ښ", 3),
      (Pbu, "ځ", 3),
      (Pbu, "څ", 3),
      (Pbu, "ڼ", 3),
      (Pbu, "ې", 3),
      (Pbu, "ۍ", 3),
      (Urd, "ٹ", 3),
      (Urd, "ڈ", 3),
      (Urd, "ڑ", 3),
      (Urd, "ں", 3),
      (Urd, "ے", 3),
      (Urd, "ھ", 2),
      (Urd, "ہ", 2),
      (Skr, "ٹ", 3),
      (Skr, "ڈ", 3),
      (Skr, "ڑ", 3),
      (Skr, "ں", 3),
      (Skr, "ے", 3),
      (Skr, "ھ", 2),
      (Skr, "ہ", 2),
      (Skr, "ٻ", 4),
      (Skr, "ڄ", 4),
      (Skr, "ڳ", 4),
      (Skr, "ݙ", 4),
      (Skr, "ݨ", 4),
    ],
    words: [
      (
        Arb,
        [
          "في", "من", "على", "أن", "هذا", "هذه", "لا", "ما", "هل",
          "إلى", "عن",
        ],
      ),
      (
        Pes,
        [
          "است", "را", "این", "آن", "که", "می", "من", "به", "از",
          "با", "برای", "چه", "نمی", "هست", "بود", "شما", "ما",
          "او",
        ],
      ),
      (
        Urd,
        [
          "ہے", "کے", "کی", "میں", "سے", "نہیں", "اور", "کو",
          "یہ", "ہیں", "تھا", "آپ", "ہم", "کیا",
        ],
      ),
      (
        Skr,
        [
          "ہے", "دے", "دی", "وچ", "توں", "نئیں", "تے", "کوں",
          "اے", "ہن", "ہا", "تساں",
        ],
      ),
      (
        Ckb,
        [
          "لە", "و", "بۆ", "ئەم", "ئەو", "من", "تۆ", "نییە", "دەکەم",
          "چی",
        ],
      ),
      (
        Pbu,
        [
          "په", "د", "او", "دا", "چې", "زه", "ته", "سره", "نه",
          "يې",
        ],
      ),
    ],
  },
]

///|
/// Lowercase words of `text`: runs of units that are not spaces, ASCII
/// punctuation or digits, or general punctuation.
fn words_of(text : String) -> Array[String] {
  let out = []
  let buf = StringBuilder()
  let flush = () => {
    let w = buf.to_string()
    if w != "" {
      out.push(w)
    }
    buf.reset()
  }
  for ch in text {
    let cp = ch.to_int()
    let separator = is_js_space(cp) ||
      (cp < 0x80 && !is_ascii_alpha(cp) && cp != '\'') ||
      (cp >= 0x2000 && cp <= 0x206F) ||
      cp == 0x060C ||
      cp == 0x061F ||
      cp == 0x06D4 ||
      cp == 0xBF ||
      cp == 0xA1 ||
      cp == 0xAB ||
      cp == 0xBB
    if separator {
      flush()
    } else {
      buf.write_char(lower_simple(cp).unsafe_to_char())
    }
  }
  flush()
  out
}

///|
/// Occurrences of `needle` in `haystack`, not overlapping.
fn occurrences(haystack : String, needle : String) -> Int {
  let mut count = 0
  let mut i = 0
  while i + needle.length() <= haystack.length() {
    if haystack.view(start_offset=i, end_offset=i + needle.length()) == needle {
      count += 1
      i += needle.length()
    } else {
      i += 1
    }
  }
  count
}

///|
/// Evidence for each language of `group` in `text`.
fn evidence(group : Group, text : String) -> Map[Lang, Int] {
  let scores : Map[Lang, Int] = Map([])
  for lang in group.langs {
    scores[lang] = 0
  }
  let words = words_of(text)
  let lower = words.join(" ")
  for marker in group.markers {
    let (lang, letters, weight) = marker
    scores[lang] = scores.get(lang).unwrap_or(0) +
      weight * occurrences(lower, letters)
  }
  for entry in group.words {
    let (lang, list) = entry
    let mut hits = 0
    for word in words {
      if list.contains(word) {
        hits += 1
      }
    }
    scores[lang] = scores.get(lang).unwrap_or(0) + hits
  }
  scores
}

///|
/// The ranking after the confusable-pair pass. When franc's best language
/// belongs to a group, the group's member with the most evidence in
/// `text` (letters and words) takes first place if it has strictly more
/// evidence than every other member and the options allow it; it swaps
/// scores with franc's choice, so the scores stay franc's and only their
/// order changes. Otherwise the ranking is returned unchanged.
fn settle_confusables(
  text : String,
  ranked : Array[(Lang, Double)],
  allow : Array[Lang],
  deny : Array[Lang],
) -> Array[(Lang, Double)] {
  guard ranked.length() > 1 else { return ranked }
  let top = ranked[0].0
  for group in groups {
    if !group.langs.contains(top) {
      continue
    }
    let scores = evidence(group, text)
    let mut best = top
    let mut best_score = scores.get(top).unwrap_or(0)
    let mut tie = false
    for lang in group.langs {
      if lang == top {
        continue
      }
      let s = scores.get(lang).unwrap_or(0)
      if s > best_score {
        best = lang
        best_score = s
        tie = false
      } else if s == best_score && best != top {
        tie = true
      }
    }
    if best == top || tie || best_score <= 0 {
      return ranked
    }
    if !allowed(best, allow, deny) {
      return ranked
    }
    // franc's choice takes the score `best` had and goes after every
    // language that scores at least as much. A language franc has no
    // profile for in this script (Sorani, which franc-min only knows in
    // Latin script) is not in the ranking; franc's choice then takes the
    // runner-up's score.
    let i = ranked.search_by(r => r.0 == best).unwrap_or(-1)
    let demoted = (top, if i >= 0 { ranked[i].1 } else { ranked[1].1 })
    let out = [(best, ranked[0].1)]
    let mut placed = false
    for k in 1..<ranked.length() {
      if k == i {
        continue
      }
      if !placed && ranked[k].1 < demoted.1 {
        out.push(demoted)
        placed = true
      }
      out.push(ranked[k])
    }
    if !placed {
      out.push(demoted)
    }
    return out
  }
  ranked
}
