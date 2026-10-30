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
  /// The script the group's evidence is written in.
  script : Script
  langs : Array[Lang]
  markers : Array[(Lang, String, Int32)]
  words : Array[(Lang, Array[String])]
}

///|
let groups : Array[Group] = [
  {
    script: Latin,
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
    script: Cyrillic,
    langs: [Rus, Ukr, Bel, Bul, Srp, Kaz, Bos],
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
          "време", "дете", "лепо", "река", "где", "увек",
          "млеко", "недеља", "хтео", "хтела", "универзитета",
          "научници", "научника", "јануара", "фебруара",
          "марта", "априла", "јула", "августа", "септембра",
          "октобра", "новембра", "децембра", "извештај",
          "општина",
        ],
      ),
      (
        Bos,
        [
          "вријеме", "дијете", "лијепо", "ријека", "гдје",
          "увијек", "млијеко", "сједмица", "хтио", "хтјела",
          "извјештај", "општина", "кахва", "хисторија",
        ],
      ),
    ],
  },
  {
    script: Latin,
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
          "povijest", "bok", "hvala", "molim", "kćer", "kći", "znanstvenici", "znanstvenika",
          "znanstveni", "znanstvene", "znanstvenik", "sveučilišta", "sveučilištu",
          "tisuća", "siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
          "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca", "nogomet",
          "nogometni", "europske", "europski", "europska", "izvješće", "izvješća",
          "momčad", "zrakoplova",
        ],
      ),
      (
        Srp,
        [
          "ko", "šta", "tokom", "takođe", "hiljadu", "hiljade", "hleb", "muzika",
          "univerzitet", "avion", "pozorište", "voz", "kafa", "lepo", "mleko", "reka",
          "vreme", "dete", "hteo", "htela", "gde", "uvek", "nedelja", "nedelju",
          "porodica", "vazduh", "istorija", "hoću", "lep", "lepa", "devojka", "pevati",
          "videti", "voleti", "razumem", "ćerka", "beše", "naučnici", "naučnika",
          "naučni", "naučne", "naučnik", "univerziteta", "univerzitetu", "januara",
          "februara", "marta", "aprila", "maja", "juna", "jula", "avgusta", "septembra",
          "oktobra", "novembra", "decembra", "fudbal", "fudbalski", "evropske", "evropski",
          "evropska", "izveštaj", "izveštaja", "opština", "opštine",
        ],
      ),
      (
        Bos,
        [
          "ko", "šta", "tokom", "također", "hiljadu", "hiljade", "hljeb", "muzika",
          "univerzitet", "avion", "pozorište", "voz", "kahva", "kafa", "lijepo",
          "mlijeko", "rijeka", "vrijeme", "dijete", "htio", "htjela", "gdje", "uvijek",
          "sedmica", "sedmicu", "porodica", "zrak", "historija", "lahko", "mehko",
          "hoću", "hvala", "ćerka", "ahbab", "naučnici", "naučnika", "naučni",
          "naučne", "naučnik", "univerziteta", "univerzitetu", "januara", "februara",
          "marta", "aprila", "maja", "juna", "jula", "augusta", "septembra", "oktobra",
          "novembra", "decembra", "fudbal", "fudbalski", "evropske", "evropski",
          "evropska", "izvještaj", "izvještaja", "općina", "općine",
        ],
      ),
    ],
  },
  {
    script: Latin,
    langs: [Ind, Zlm],
    markers: [],
    words: [
      (
        Ind,
        [
          "bisa", "uang", "karena", "nggak", "gak", "enggak", "aja", "kantor", "mobil",
          "sepeda", "dong", "banget", "sih", "kok", "cewek", "cowok", "kalian", "mau",
          "apakah", "teman", "bahwa", "setelah", "sesudah", "pemerintah", "kendaraan",
          "berbagai", "internasional", "tentara", "polisi", "perusahaan", "sedangkan",
          "mengatakan", "universitas", "nomor", "proyek", "kualitas", "aktivitas",
          "komunitas", "kapasitas", "identitas", "musik", "film", "agustus", "desember",
          "maret", "juni", "juli", "organisasi", "koran", "bilang",
        ],
      ),
      (
        Zlm,
        [
          "boleh", "wang", "kerana", "awak", "nak", "sahaja", "pejabat", "kereta",
          "basikal", "encik", "bilik", "kawan", "bagaimanakah", "adakah", "mahu",
          "telefon", "universiti", "bahawa", "selepas", "kerajaan", "kenderaan",
          "pelbagai", "antarabangsa", "tentera", "polis", "syarikat", "iaitu", "ialah",
          "semasa", "baharu", "jabatan", "hospital", "bilangan", "menerusi", "sebarang",
          "akhbar", "filem", "muzik", "projek", "kualiti", "aktiviti", "komuniti",
          "kapasiti", "identiti", "ogos", "disember", "mac", "julai", "pertubuhan",
          "nombor",
        ],
      ),
    ],
  },
  {
    script: Latin,
    langs: [Run, Kin],
    markers: [
      (Kin, "cy", 2),
      (Kin, "jy", 2),
      (Kin, "shy", 2),
      (Kin, "by", 2),
      (Run, "vy", 2),
    ],
    words: [
      (
        Kin,
        [
          "cyane", "ibyo", "byose", "iki", "cyangwa", "kuko", "ndetse", "nyuma",
          "ariko", "u", "ubwo", "rwa",
        ],
      ),
      (
        Run,
        [
          "cane", "ivyo", "vyose", "ico", "canke", "kubera", "ningoga", "inyuma",
          "mugabo", "yuko", "kuri", "rya",
        ],
      ),
    ],
  },
  {
    script: Latin,
    langs: [Tgl, Ceb],
    markers: [],
    words: [
      (
        Tgl,
        [
          "ng", "hindi", "ito", "iyan", "iyon", "ay", "po", "niya", "ko", "mo", "kayo",
          "akin", "kanya", "bakit", "paano", "saan", "may", "din", "rin", "talaga",
          "noong", "nang", "mula", "ayon", "isang", "kanilang", "nito", "dahil",
          "upang", "sinabi", "ngunit", "subalit", "pa", "rito",
        ],
      ),
      (
        Ceb,
        [
          "ug", "og", "dili", "kini", "kana", "unsa", "ngano", "naa", "kaayo", "nga",
          "imong", "akong", "nimo", "niini", "adto", "diha", "asa", "pud", "sad",
          "gyud", "usa", "gikan", "miingon", "giingon", "kaniadtong", "karon", "diin",
          "kining", "pinaagi", "apan", "tungod", "aron", "didto", "kaayo",
        ],
      ),
    ],
  },
  {
    script: Latin,
    langs: [Hau, Fuv],
    markers: [(Hau, "ƙ", 2), (Hau, "ts", 1), (Fuv, "ŋ", 3), (Fuv, "ɲ", 3)],
    words: [
      (
        Hau,
        [
          "da", "na", "ta", "ya", "wanda", "wadda", "shi", "ita", "sun", "su", "kuma",
          "amma", "daga", "zai", "za", "iya", "wannan", "don", "ga", "suka", "ake",
          "yana", "tana", "akwai", "kamar", "bayan", "shekara",
        ],
      ),
      (
        Fuv,
        [
          "je", "ha", "be", "nde", "ɗum", "mari", "der", "ko", "e", "kanko", "kanjum",
          "ngam", "nden", "fu", "fuu", "ɓe", "ɗon", "ndu", "ngal", "dow", "nder",
          "ka", "noone", "woni", "wonaa",
        ],
      ),
    ],
  },
  {
    script: Latin,
    langs: [Jav, Sun],
    markers: [(Jav, "dh", 1), (Jav, "th", 1), (Sun, "eu", 1)],
    words: [
      (
        Jav,
        [
          "ing", "sing", "lan", "kanggo", "iku", "ora", "wis", "kang", "menawa",
          "saka", "uga", "dadi", "marang", "karo", "iki", "ana", "kabeh", "banjur",
          "bakal", "isih", "nanging",
        ],
      ),
      (
        Sun,
        [
          "anu", "jeung", "teh", "téh", "sareng", "ti", "ka", "éta", "ieu", "henteu",
          "tiasa", "nu", "oge", "ogé", "geus", "kana", "pikeun", "keur", "jang",
          "urang", "sanés", "tapi", "bari",
        ],
      ),
    ],
  },
  {
    script: Arabic,
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
/// The group of related languages that holds `lang` in `script`, if any.
/// Serbian and Bosnian are in one group for Cyrillic and another for
/// Latin script.
fn group_of(lang : Lang, script : Script) -> Group? {
  for group in groups {
    if group.script == script && group.langs.contains(lang) {
      return Some(group)
    }
  }
  None
}

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
fn occurrences(haystack : String, needle : String) -> Int32 {
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
/// Evidence for each language of `group` in the words of a text. Markers
/// never contain a space, so counting them word by word is the same as
/// counting them in the text.
fn evidence(group : Group, words : Map[String, Int32]) -> Map[Lang, Int32] {
  let scores : Map[Lang, Int32] = Map([])
  for lang in group.langs {
    scores[lang] = 0
  }
  for marker in group.markers {
    let (lang, letters, weight) = marker
    let mut found = 0
    for word, n in words {
      found += n * occurrences(word, letters)
    }
    scores[lang] = scores.get(lang).unwrap_or(0) + weight * found
  }
  for entry in group.words {
    let (lang, list) = entry
    let mut hits = 0
    for word in list {
      hits += words.get_or_default(word, 0)
    }
    scores[lang] = scores.get(lang).unwrap_or(0) + hits
  }
  scores
}

///|
/// The ranking after the confusable-pair pass. When franc's best language
/// belongs to a group in `script`, the members with the most evidence in
/// the text (letters and words) are found; if they have more than franc's
/// choice, the one franc ranks highest among them takes first place, when
/// the options allow it. It swaps scores with franc's choice, so the
/// scores stay franc's and only their order changes. Otherwise the ranking
/// is returned unchanged.
fn settle_confusables(
  stats : TextStats,
  ranked : Array[(Lang, Double)],
  allow : Array[Lang],
  deny : Array[Lang],
  script~ : Script = Latin,
) -> Array[(Lang, Double)] {
  guard ranked.length() > 1 else { return ranked }
  let top = ranked[0].0
  guard group_of(top, script) is Some(group) else { return ranked }
  let scores = evidence(group, stats.words)
  let mut best_score = scores.get(top).unwrap_or(0)
  for lang in group.langs {
    best_score = best_score.max(scores.get(lang).unwrap_or(0))
  }
  if best_score <= 0 || scores.get(top).unwrap_or(0) == best_score {
    return ranked
  }
  // The leaders in franc's order; members franc did not rank come last.
  let leaders = group.langs.filter(lang => {
    scores.get(lang).unwrap_or(0) == best_score
  })
  let position = (lang : Lang) => {
    ranked.search_by(r => r.0 == lang).unwrap_or(ranked.length())
  }
  leaders.sort_by((a, b) => position(a) - position(b))
  let best = leaders[0]
  if !allowed(best, allow, deny) {
    return ranked
  }
  promote(ranked, best)
}

///|
/// `ranked` with `best` first. franc's choice takes the score `best` had
/// and goes after every language that scores at least as much, so the
/// scores stay franc's and only their order changes. A language franc has
/// no profile for in this script (Sorani, which franc-min only knows in
/// Latin script) is not in the ranking; franc's choice then takes the
/// runner-up's score.
fn promote(
  ranked : Array[(Lang, Double)],
  best : Lang,
) -> Array[(Lang, Double)] {
  let top = ranked[0].0
  if best == top {
    return ranked
  }
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
  out
}
