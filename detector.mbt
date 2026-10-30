///|
/// A language detector with fixed options. `detect`, `rank` and
/// `segments` with the same options give the same results; a `Detector`
/// works out once which languages the options leave, instead of on every
/// call, so build one for a stream of texts.
pub struct Detector {
  priv options : Options
  /// For each script index, whether each of its languages is allowed.
  priv masks : FixedArray[FixedArray[Bool]]
}

///|
/// A detector for `options` (by default those of `Options::new()`).
pub fn Detector::new(options~ : Options = default_options) -> Detector {
  { options, masks: language_masks(options.allow, options.deny), }
}

///|
let default_detector : Detector = Detector::new()

///|
/// The detector for `options`, shared when they are the defaults.
fn detector_for(options : Options) -> Detector {
  if physical_equal(options, default_options) {
    default_detector
  } else {
    Detector::new(options~)
  }
}

///|
/// The options this detector was built with.
pub fn Detector::options(self : Detector) -> Options {
  self.options
}

///|
/// The statistics of `text` as this detector's options prepare it.
fn Detector::stats_of(self : Detector, text : String) -> TextStats {
  TextStats::of(
    prepared(text, self.options),
    with_words=self.options.mode == Enhanced,
  )
}

///|
/// Candidate languages with scores between 0 and 1, best first, as
/// returned by the free function `rank`.
pub fn Detector::rank(self : Detector, text : String) -> Array[(Lang, Double)] {
  self.ranked(self.stats_of(text))
}

///|
/// The ranking for a text that `stats` describe.
fn Detector::ranked(
  self : Detector,
  stats : TextStats,
) -> Array[(Lang, Double)] {
  match ranking(stats, self.options, self.masks) {
    Some((_, ranked)) => ranked
    None => []
  }
}

///|
/// The most likely language of `text`, as returned by the free function
/// `detect`.
pub fn Detector::detect(self : Detector, text : String) -> Detection? {
  self.decide(self.stats_of(text))
}

///|
/// The detection for a text that `stats` describe.
fn Detector::decide(self : Detector, stats : TextStats) -> Detection? {
  let options = self.options
  guard ranking(stats, options, self.masks) is Some((script, ranked)) else {
    return None
  }
  let lang = ranked[0].0
  let (margin, runner_up) = if ranked.length() > 1 {
    (ranked[0].1 - ranked[1].1, Some(ranked[1].0))
  } else {
    (1.0, None)
  }
  let (confidence, reliable) = match options.mode {
    Franc =>
      (
        margin,
        margin >= reliable_min_margin && stats.length >= reliable_min_length,
      )
    Enhanced => {
      let clues = clues(stats.words, lang, runner_up, script~)
      let confidence = (margin + evidence_weight * clues.evidence.to_double()).min(
        1.0,
      )
      let threshold = if stats.length >= reliable_min_length {
        reliable_min_confidence
      } else {
        short_reliable_min_confidence
      }
      (confidence, confidence >= threshold && !clues.contested)
    }
  }
  Some({ lang, script, confidence, reliable, margin, runner_up, })
}
