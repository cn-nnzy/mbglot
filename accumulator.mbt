///|
/// Identifies the language of a stream of text fed in chunks, such as the
/// messages of a chat or the lines of a long file, without reading what
/// came before again. It keeps the counts detection needs (characters per
/// script, trigrams and, in `Mode::Enhanced`, words), so a chunk costs
/// time in proportion to its own length, and asking for the language costs
/// time in proportion to the number of distinct trigrams seen.
///
/// The result is that of `detect` on the chunks joined with line breaks,
/// with two differences on long streams: franc looks only at the first
/// 2048 UTF-16 code units of a text, while an accumulator uses every
/// chunk, and the script of each chunk is judged on its first 2048 code
/// units. Markup is removed chunk by chunk, so a URL or tag split across
/// two chunks is not recognised.
pub struct Accumulator {
  priv detector : Detector
  priv stats : TextStats
  /// The last code unit of the cleaned text so far, for the trigram that
  /// spans the line break before the next chunk.
  priv mut last_unit : Int32?
  priv mut chunks : Int32
}

///|
/// An empty accumulator with this detector's options.
pub fn Detector::accumulator(self : Detector) -> Accumulator {
  {
    detector: self,
    stats: {
      length: 0,
      sample_length: 0,
      scripts: FixedArray::make(script_ranges.length(), 0),
      grams: Map([]),
      words: Map([]),
    },
    last_unit: None,
    chunks: 0,
  }
}

///|
/// An empty accumulator for `options` (by default those of
/// `Options::new()`).
pub fn Accumulator::new(options~ : Options = default_options) -> Accumulator {
  detector_for(options).accumulator()
}

///|
/// Adds `chunk` to the stream, after a line break when it is not the
/// first.
pub fn Accumulator::feed(self : Accumulator, chunk : String) -> Unit {
  let options = self.detector.options
  let text = prepared(chunk, options)
  let separator = if self.chunks > 0 { 1 } else { 0 }
  self.chunks += 1
  self.stats.length += separator + text.length()
  self.stats.sample_length += separator + text.length()
  let scripts = script_counts(text)
  for s in 0..<scripts.length() {
    self.stats.scripts[s] += scripts[s]
  }
  let units = clean_units(text)
  if units.is_empty() {
    return
  }
  if self.last_unit is Some(last) {
    // The line break between the chunks is a space in the cleaned text.
    let key = pack(last, 0x20, units[0])
    self.stats.grams[key] = self.stats.grams.get_or_default(key, 0) + 1
  }
  add_trigrams(self.stats.grams, units)
  self.last_unit = units.last()
  if options.mode == Enhanced {
    count_words(self.stats.words, words_of(text))
  }
}

///|
/// The most likely language of everything fed so far; see `detect`.
pub fn Accumulator::detect(self : Accumulator) -> Detection? {
  self.detector.decide(self.stats)
}

///|
/// The candidate languages for everything fed so far; see `rank`.
pub fn Accumulator::rank(self : Accumulator) -> Array[(Lang, Double)] {
  self.detector.ranked(self.stats)
}

///|
/// UTF-16 code units fed so far, counting a line break between chunks,
/// after markup removal when the options remove it.
pub fn Accumulator::length(self : Accumulator) -> Int32 {
  self.stats.length
}

///|
/// Forgets everything fed so far.
pub fn Accumulator::reset(self : Accumulator) -> Unit {
  self.stats.length = 0
  self.stats.sample_length = 0
  self.stats.scripts.fill(0)
  self.stats.grams.clear()
  self.stats.words.clear()
  self.last_unit = None
  self.chunks = 0
}
