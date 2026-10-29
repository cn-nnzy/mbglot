///|
/// What detection needs to know about a text: its length, how many
/// characters each script has, its trigrams and its words. `detect` builds
/// it from one text; an `Accumulator` adds to it chunk by chunk.
priv struct TextStats {
  /// UTF-16 code units of the text.
  mut length : Int32
  /// UTF-16 code units of the part franc samples: the first
  /// `max_sample_length` of one text, all of an accumulated stream.
  mut sample_length : Int32
  /// Code points per script, as `script_counts` counts them.
  scripts : FixedArray[Int32]
  /// Trigram key (see `pack`) -> occurrences in the sample.
  grams : Map[Int64, Int32]
  /// Lowercase word (see `words_of`) -> occurrences, in order of first
  /// occurrence. Only filled for `Mode::Enhanced`.
  words : Map[String, Int32]
}

///|
/// Adds the occurrences of `words` to `counts`.
fn count_words(counts : Map[String, Int32], words : Array[String]) -> Unit {
  for word in words {
    counts[word] = counts.get_or_default(word, 0) + 1
  }
}

///|
/// The statistics of `text`. Words are only counted `with_words`.
fn TextStats::of(text : String, with_words~ : Bool) -> TextStats {
  let sample = if text.length() > max_sample_length {
    text.view(end_offset=max_sample_length).to_owned()
  } else {
    text
  }
  let grams = trigram_counts(sample)
  let words : Map[String, Int32] = Map([])
  if with_words {
    count_words(words, words_of(text))
  }
  {
    length: text.length(),
    sample_length: sample.length(),
    scripts: script_counts(text),
    grams,
    words,
  }
}

///|
/// Index into `all_scripts` of the most frequent script, ties to the
/// script listed first, or -1 when no character belongs to any script.
fn TextStats::top_script(self : TextStats) -> Int32 {
  let mut best = -1
  let mut best_count = 0
  for s in 0..<self.scripts.length() {
    if self.scripts[s] > best_count {
      best = s
      best_count = self.scripts[s]
    }
  }
  best
}
