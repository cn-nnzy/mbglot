///|
/// What the letters and common words of a text say about the best
/// language against the runner-up, beyond franc's trigram scores.
priv struct Clues {
  /// Letters and words that point to the best language rather than the
  /// runner-up: the best language's lead in its group of related languages
  /// (see `groups`) plus its lead in common words (see `stop_words`), each
  /// counted only when positive.
  evidence : Int32
  /// The best language and the runner-up belong to one group of related
  /// languages, and nothing in the text prefers the best one.
  contested : Bool
}

///|
/// The clues in the words of a text for `top` against `runner_up`.
fn clues(words : Map[String, Int32], top : Lang, runner_up : Lang?) -> Clues {
  let mut total = 0
  let mut contested = false
  for group in groups {
    if !group.langs.contains(top) {
      continue
    }
    let scores = evidence(group, words)
    let own = scores.get(top).unwrap_or(0)
    let mut rival = 0
    for lang in group.langs {
      if lang != top {
        rival = rival.max(scores.get(lang).unwrap_or(0))
      }
    }
    if own > rival {
      total += own - rival
    } else if runner_up is Some(r) && group.langs.contains(r) {
      contested = true
    }
    break
  }
  if runner_up is Some(r) {
    let lead = stop_word_hits(top, words) - stop_word_hits(r, words)
    if lead > 0 {
      total += lead
    }
  }
  { evidence: total, contested, }
}
