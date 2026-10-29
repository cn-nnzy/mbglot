///|
/// One step of the decision, as recorded by `explain`.
pub(all) enum Step {
  /// franc's trigram distance ranked this language first.
  Trigrams(Lang)
  /// The shares of kana, Han and Hangul decided Chinese, Japanese or Korean.
  ScriptShare(Lang)
  /// In a short text, these common words moved the language to the top.
  CommonWords(Lang, Array[String])
  /// These letters and words settled the language among related ones.
  RelatedLanguages(Lang, Array[String])
  /// A near tie with the second language, broken for the language with
  /// more speakers.
  NearTie(Lang, Lang)
} derive(Eq, Debug)

///|
/// How one trigram of the text weighed between the detected language and
/// the runner-up in franc's distance.
pub(all) struct TrigramScore {
  /// Three UTF-16 code units of the cleaned, lowercased text; spaces mark
  /// word boundaries.
  trigram : String
  /// Occurrences in the text.
  count : Int32
  /// Rank in the detected language's profile (0 is the most frequent),
  /// `None` if the profile lacks it.
  rank : Int32?
  /// Rank in the runner-up's profile.
  runner_up_rank : Int32?
  /// The runner-up's distance for this trigram minus the detected
  /// language's: positive when it favours the detected language.
  gain : Int32
} derive(Eq, Debug)

///|
/// Why `detect` decided as it did.
pub(all) struct Explanation {
  /// What `detect` returns for the text.
  detection : Detection?
  /// franc's choice, then each pass of `Mode::Enhanced` that changed the
  /// language at the top, in order.
  steps : Array[Step]
  /// The trigrams of the text that weigh differently for the detected
  /// language and the runner-up, those that favour the detected language
  /// most first. Empty when there is no runner-up or the languages were
  /// not ranked by trigrams.
  trigrams : Array[TrigramScore]
}

///|
/// The common words of `lang` in `text`, in order.
fn common_words_of(lang : Lang, text : String) -> Array[String] {
  guard stop_words.search_by(entry => entry.0 == lang) is Some(i) else {
    return []
  }
  let list = stop_words[i].1
  words_of(text).filter(word => list.contains(word))
}

///|
/// The letters and words of `text` that point to `lang` rather than to
/// `previous`, franc's choice before, in their group of related languages.
fn group_clues(lang : Lang, previous : Lang, text : String) -> Array[String] {
  guard groups.search_by(group => group.langs.contains(previous)) is Some(g) else {
    return []
  }
  let group = groups[g]
  let words = words_of(text)
  let lower = words.join(" ")
  let found = []
  let marks = (target : Lang, letters : String) => {
    group.markers.iter().any(m => m.0 == target && m.1 == letters)
  }
  for marker in group.markers {
    let (target, letters, _) = marker
    if target == lang &&
      !marks(previous, letters) &&
      occurrences(lower, letters) > 0 &&
      !found.contains(letters) {
      found.push(letters)
    }
  }
  let list_of = (target : Lang) => {
    match group.words.search_by(e => e.0 == target) {
      Some(i) => group.words[i].1
      None => []
    }
  }
  let own = list_of(lang)
  let other = list_of(previous)
  for word in words {
    if own.contains(word) && !other.contains(word) && !found.contains(word) {
      found.push(word)
    }
  }
  found
}

///|
/// The rank of trigram `key` in the profile of the language at position
/// `i` of `index`.
fn rank_in(index : ScriptIndex, key : Int64, i : Int32) -> Int32? {
  guard index.postings.get(key) is Some(list) else { return None }
  for posting in list {
    if posting.0 == i {
      return Some(posting.1)
    }
  }
  None
}

///|
/// franc's distance for one trigram that occurs `count` times.
fn trigram_distance(count : Int32, rank : Int32?) -> Int32 {
  match rank {
    Some(r) => (count - r - 1).abs()
    None => max_difference
  }
}

///|
/// The trigrams of `text` scored for `lang` against `runner_up` in the
/// profiles of `script`.
fn trigram_scores(
  text : String,
  script : Script,
  lang : Lang,
  runner_up : Lang,
) -> Array[TrigramScore] {
  let mut found = None
  for index in script_indexes {
    if index.script == script {
      found = Some(index)
    }
  }
  guard found is Some(index) else { return [] }
  let position = (target : Lang) => {
    let mut at = None
    for i, l in index.langs {
      if l == target {
        at = Some(i)
      }
    }
    at
  }
  guard position(lang) is Some(a) && position(runner_up) is Some(b) else {
    return []
  }
  let sample = if text.length() > max_sample_length {
    text.view(end_offset=max_sample_length).to_owned()
  } else {
    text
  }
  let scores : Array[TrigramScore] = []
  for gram in trigram_keys(sample) {
    let (key, count) = gram
    let rank = rank_in(index, key, a)
    let runner_up_rank = rank_in(index, key, b)
    let gain = trigram_distance(count, runner_up_rank) -
      trigram_distance(count, rank)
    if gain != 0 {
      scores.push({ trigram: unpack(key), count, rank, runner_up_rank, gain, })
    }
  }
  // Highest gain first; equal gains keep the order of the text's trigrams.
  let order = scores.mapi((i, score) => (i, score))
  order.sort_by((x, y) => {
    if x.1.gain != y.1.gain {
      y.1.gain - x.1.gain
    } else {
      x.0 - y.0
    }
  })
  order.map(entry => entry.1)
}

///|
/// Why this detector identifies `text` as it does: the detection, the
/// steps that decided it and the trigrams that weigh for and against it.
pub fn Detector::explain(self : Detector, text : String) -> Explanation {
  let detection = self.detect(text)
  let prepared = prepared(text, self.options)
  let steps = []
  let ranked = ranking(prepared, self.options, self.masks, steps~)
  let trigrams = match (detection, ranked) {
    (Some({ lang, runner_up: Some(other), script, .. }), Some(_)) =>
      trigram_scores(prepared, script, lang, other)
    _ => []
  }
  { detection, steps, trigrams, }
}

///|
/// Why `detect` identifies `text` as it does under `options`; see
/// `Detector::explain`.
pub fn explain(
  text : String,
  options~ : Options = default_options,
) -> Explanation {
  detector_for(options).explain(text)
}
