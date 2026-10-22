///|
/// Texts shorter than this many UTF-16 code units (after markup removal)
/// get the word signal in `Mode::Enhanced`.
pub let short_text_length : Int32 = 40

///|
/// How much one common word adds to a language's score in short texts.
/// franc's scores of the leading candidates in a short text usually differ
/// by a few hundredths, so one word moves a language ahead of candidates
/// close behind it but not of ones far behind. Chosen on the Tatoeba
/// benchmark (0.02 to 0.25 tried; gains level off above 0.1), so its
/// short-text figures are optimistic for other texts.
let word_weight : Double = 0.1

///|
/// Very common words (articles, pronouns, prepositions, auxiliaries) per
/// language, lowercase. Short texts have too few trigrams for franc's
/// statistics, but usually contain one or two of these.
let stop_words : Array[(Lang, Array[String])] = [
  (
    Eng,
    [
      "the", "a", "an", "is", "are", "was", "were", "be", "been", "i", "you", "he",
      "she", "it", "we", "they", "me", "my", "your", "his", "her", "our", "their",
      "this", "that", "these", "those", "of", "to", "in", "on", "at", "for", "with",
      "and", "or", "but", "not", "do", "does", "did", "have", "has", "had", "will",
      "would", "can", "could", "what", "who", "where", "when", "why", "how", "there",
      "here", "very", "from", "by", "about", "don't", "i'm", "it's", "please", "thanks",
      "yes", "no",
    ],
  ),
  (
    Spa,
    [
      "el", "la", "los", "las", "un", "una", "y", "o", "pero", "de", "del", "al",
      "en", "con", "por", "para", "es", "son", "está", "están", "ser", "estar",
      "yo", "tú", "él", "ella", "nosotros", "ellos", "usted", "mi", "tu", "su",
      "me", "te", "se", "lo", "le", "que", "qué", "quién", "dónde", "cuándo",
      "cómo", "no", "sí", "muy", "hay", "tengo", "tiene", "esto", "eso", "este",
      "esta", "también", "gracias",
    ],
  ),
  (
    Por,
    [
      "o", "a", "os", "as", "um", "uma", "e", "ou", "mas", "de", "do", "da", "dos",
      "das", "em", "no", "na", "nos", "nas", "com", "por", "para", "é", "são",
      "está", "estão", "ser", "estar", "eu", "você", "ele", "ela", "nós", "eles",
      "meu", "minha", "seu", "sua", "me", "te", "se", "que", "quem", "onde", "quando",
      "como", "não", "sim", "muito", "há", "tenho", "tem", "isto", "isso", "este",
      "esta", "também", "obrigado", "obrigada",
    ],
  ),
  (
    Fra,
    [
      "le", "la", "les", "un", "une", "des", "du", "de", "et", "ou", "mais", "en",
      "dans", "sur", "avec", "pour", "par", "est", "sont", "suis", "es", "être",
      "avoir", "ai", "as", "a", "je", "tu", "il", "elle", "nous", "vous", "ils",
      "elles", "mon", "ma", "mes", "ton", "ta", "son", "sa", "ses", "ce", "cette",
      "qui", "que", "quoi", "où", "quand", "comment", "pourquoi", "ne", "pas", "oui",
      "non", "très", "c'est", "j'ai", "merci", "au", "aux",
    ],
  ),
  (
    Deu,
    [
      "der", "die", "das", "den", "dem", "des", "ein", "eine", "einen", "und", "oder",
      "aber", "in", "im", "auf", "mit", "für", "von", "zu", "ist", "sind", "war",
      "bin", "bist", "sein", "haben", "habe", "hat", "ich", "du", "er", "sie", "es",
      "wir", "ihr", "mein", "dein", "nicht", "kein", "was", "wer", "wo", "wann",
      "wie", "warum", "ja", "nein", "sehr", "auch", "noch", "schon", "danke", "bitte",
    ],
  ),
  (
    Ita,
    [
      "il", "lo", "la", "i", "gli", "le", "un", "uno", "una", "e", "o", "ma", "di",
      "del", "della", "in", "nel", "nella", "con", "per", "da", "su", "è", "sono",
      "sei", "essere", "ho", "hai", "ha", "io", "tu", "lui", "lei", "noi", "voi",
      "loro", "mio", "mia", "tuo", "suo", "che", "chi", "dove", "quando", "come",
      "perché", "non", "sì", "molto", "anche", "questo", "questa", "grazie",
    ],
  ),
  (
    Nld,
    [
      "de", "het", "een", "en", "of", "maar", "in", "op", "met", "voor", "van", "naar",
      "is", "zijn", "was", "ben", "bent", "heb", "hebt", "heeft", "ik", "jij", "je",
      "hij", "zij", "ze", "wij", "we", "jullie", "mijn", "jouw", "niet", "geen",
      "wat", "wie", "waar", "wanneer", "hoe", "waarom", "ja", "nee", "heel", "erg",
      "ook", "dit", "dat", "dank", "alsjeblieft",
    ],
  ),
  (
    Pol,
    [
      "i", "w", "na", "z", "do", "nie", "to", "że", "się", "jest", "są", "był",
      "była", "jestem", "jesteś", "ja", "ty", "on", "ona", "my", "wy", "oni", "mój",
      "moja", "twój", "co", "kto", "gdzie", "kiedy", "jak", "dlaczego", "tak", "bardzo",
      "też", "ale", "lub", "albo", "od", "dla", "przez", "ten", "ta", "dziękuję",
      "proszę", "mam", "masz", "ma",
    ],
  ),
  (
    Ces,
    [
      "a", "v", "na", "s", "z", "do", "ne", "to", "že", "se", "je", "jsou", "byl",
      "byla", "jsem", "jsi", "já", "ty", "on", "ona", "my", "vy", "oni", "můj",
      "moje", "co", "kdo", "kde", "kdy", "jak", "proč", "ano", "velmi", "také",
      "ale", "nebo", "od", "pro", "ten", "ta", "děkuji", "prosím", "mám", "máš",
      "má",
    ],
  ),
  (
    Swe,
    [
      "en", "ett", "och", "eller", "men", "i", "på", "med", "för", "av", "till",
      "från", "är", "var", "har", "hade", "jag", "du", "han", "hon", "det", "den",
      "vi", "ni", "de", "min", "mitt", "din", "inte", "vad", "vem", "när", "hur",
      "varför", "ja", "nej", "mycket", "också", "tack", "som", "om",
    ],
  ),
  (
    Hun,
    [
      "a", "az", "egy", "és", "vagy", "de", "nem", "is", "van", "volt", "vagyok",
      "én", "te", "ő", "mi", "ti", "ők", "ez", "mit", "ki", "hol", "mikor", "hogy",
      "hogyan", "miért", "igen", "nagyon", "már", "még", "köszönöm", "kérem",
      "meg", "el",
    ],
  ),
  (
    Ron,
    [
      "un", "o", "și", "sau", "dar", "în", "pe", "cu", "pentru", "de", "la", "din",
      "este", "e", "sunt", "era", "am", "ai", "are", "eu", "tu", "el", "ea", "noi",
      "voi", "ei", "meu", "mea", "nu", "ce", "cine", "unde", "când", "cum", "da",
      "foarte", "mulțumesc", "vă", "rog", "acest", "această",
    ],
  ),
  (
    Tur,
    [
      "bir", "ve", "veya", "ama", "bu", "şu", "o", "ben", "sen", "biz", "siz", "onlar",
      "benim", "senin", "değil", "var", "yok", "ne", "kim", "nerede", "nasıl",
      "neden", "evet", "hayır", "çok", "de", "da", "mi", "mı", "mu", "mü", "için",
      "ile", "teşekkürler", "lütfen",
    ],
  ),
  (
    Ind,
    [
      "yang", "dan", "di", "ke", "dari", "ini", "itu", "dengan", "untuk", "tidak",
      "saya", "aku", "kamu", "anda", "dia", "kami", "kita", "mereka", "apa", "siapa",
      "kapan", "bagaimana", "kenapa", "mengapa", "ya", "sangat", "juga", "sudah",
      "belum", "akan", "bisa", "ada", "terima", "kasih", "tolong",
    ],
  ),
  (
    Zlm,
    [
      "yang", "dan", "di", "ke", "dari", "ini", "itu", "dengan", "untuk", "tidak",
      "tak", "saya", "aku", "awak", "kamu", "anda", "dia", "kami", "kita", "mereka",
      "apa", "siapa", "bila", "bagaimana", "kenapa", "mengapa", "ya", "sangat", "juga",
      "sudah", "belum", "akan", "boleh", "ada", "terima", "kasih", "tolong",
    ],
  ),
  (
    Vie,
    [
      "và", "là", "của", "có", "không", "tôi", "bạn", "anh", "chị", "em",
      "nó", "chúng", "họ", "này", "đó", "gì", "ai", "đâu", "khi", "nào",
      "sao", "tại", "rất", "cũng", "đã", "sẽ", "đang", "được", "với",
      "cho", "trong", "một", "những", "các", "cảm", "ơn",
    ],
  ),
  (
    Tgl,
    [
      "ang", "ng", "sa", "na", "at", "ay", "si", "ni", "mga", "ako", "ikaw", "ka",
      "siya", "kami", "tayo", "kayo", "sila", "ko", "mo", "niya", "ito", "iyan",
      "iyon", "hindi", "oo", "ano", "sino", "saan", "kailan", "paano", "bakit", "po",
      "salamat", "may", "wala",
    ],
  ),
  (
    Swh,
    [
      "na", "ya", "wa", "za", "la", "kwa", "ni", "si", "katika", "mimi", "wewe",
      "yeye", "sisi", "ninyi", "wao", "huu", "hii", "hiyo", "nini", "nani", "wapi",
      "lini", "vipi", "ndiyo", "hapana", "sana", "pia", "asante", "tafadhali",
    ],
  ),
  (
    Hrv,
    [
      "i", "u", "na", "s", "sa", "za", "od", "do", "je", "su", "sam", "si", "smo",
      "ste", "biti", "ja", "ti", "on", "ona", "mi", "vi", "oni", "moj", "tvoj", "ne",
      "da", "što", "tko", "gdje", "kada", "kako", "zašto", "vrlo", "jako", "također",
      "hvala", "molim",
    ],
  ),
  (
    Srp,
    [
      "i", "u", "na", "s", "sa", "za", "od", "do", "je", "su", "sam", "si", "smo",
      "ste", "biti", "ja", "ti", "on", "ona", "mi", "vi", "oni", "moj", "tvoj", "ne",
      "da", "šta", "ko", "gde", "kada", "kako", "zašto", "vrlo", "jako", "takođe",
      "hvala", "molim",
    ],
  ),
  (
    Bos,
    [
      "i", "u", "na", "s", "sa", "za", "od", "do", "je", "su", "sam", "si", "smo",
      "ste", "biti", "ja", "ti", "on", "ona", "mi", "vi", "oni", "moj", "tvoj", "ne",
      "da", "šta", "ko", "gdje", "kada", "kako", "zašto", "vrlo", "jako", "također",
      "hvala", "molim",
    ],
  ),
  (
    Rus,
    [
      "и", "в", "не", "на", "я", "ты", "он", "она", "мы", "вы",
      "они", "что", "это", "как", "но", "или", "с", "к", "по",
      "из", "за", "от", "для", "у", "мой", "твой", "кто", "где",
      "когда", "почему", "да", "нет", "очень", "тоже", "есть",
      "был", "была", "спасибо", "пожалуйста", "меня",
      "тебя",
    ],
  ),
  (
    Ukr,
    [
      "і", "й", "та", "в", "у", "не", "на", "я", "ти", "він", "вона",
      "ми", "ви", "вони", "що", "це", "як", "але", "або", "з",
      "до", "по", "за", "від", "для", "мій", "твій", "хто",
      "де", "коли", "чому", "так", "ні", "дуже", "теж", "є",
      "був", "була", "дякую", "будь", "ласка", "мене", "тебе",
    ],
  ),
  (
    Bul,
    [
      "и", "в", "не", "на", "аз", "ти", "той", "тя", "ние", "вие",
      "те", "какво", "това", "как", "но", "или", "с", "към",
      "по", "от", "за", "до", "при", "моят", "моя", "твоят",
      "кой", "къде", "кога", "защо", "да", "много", "също",
      "е", "са", "съм", "си", "беше", "благодаря", "моля",
      "ме", "ще",
    ],
  ),
]

///|
/// Number of `words` that are common words of `lang`.
fn stop_word_hits(lang : Lang, words : Array[String]) -> Int32 {
  guard stop_words.search_by(entry => entry.0 == lang) is Some(i) else {
    return 0
  }
  let list = stop_words[i].1
  let mut hits = 0
  for word in words {
    if list.contains(word) {
      hits += 1
    }
  }
  hits
}

///|
/// The ranking after the short-text word signal: each candidate with a
/// list of common words gets `word_weight` added to franc's score for
/// every word of the text in that list, and the candidate with the
/// highest total moves to the top (see `promote`). Ties keep franc's
/// order, and texts of `short_text_length` or more are left alone.
fn short_text_signal(
  text : String,
  ranked : Array[(Lang, Double)],
) -> Array[(Lang, Double)] {
  if text.length() >= short_text_length || ranked.length() < 2 {
    return ranked
  }
  let words = words_of(text)
  if words.is_empty() {
    return ranked
  }
  let mut best = ranked[0].0
  let mut best_total = ranked[0].1 +
    word_weight * stop_word_hits(best, words).to_double()
  for entry in ranked[1:] {
    let (lang, score) = entry
    let total = score + word_weight * stop_word_hits(lang, words).to_double()
    if total > best_total {
      best = lang
      best_total = total
    }
  }
  promote(ranked, best)
}
