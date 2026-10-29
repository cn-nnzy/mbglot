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
/// Candidate languages with scores between 0 and 1, best first, as
/// returned by the free function `rank`.
pub fn Detector::rank(self : Detector, text : String) -> Array[(Lang, Double)] {
  match ranking(prepared(text, self.options), self.options, self.masks) {
    Some((_, ranked)) => ranked
    None => []
  }
}

///|
/// The most likely language of `text`, as returned by the free function
/// `detect`.
pub fn Detector::detect(self : Detector, text : String) -> Detection? {
  let options = self.options
  let text = prepared(text, options)
  guard ranking(text, options, self.masks) is Some((script, ranked)) else {
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
        margin >= reliable_min_margin && text.length() >= reliable_min_length,
      )
    Enhanced => {
      let clues = clues(text, lang, runner_up)
      let confidence = (margin + evidence_weight * clues.evidence.to_double()).min(
        1.0,
      )
      let threshold = if text.length() >= reliable_min_length {
        reliable_min_confidence
      } else {
        short_reliable_min_confidence
      }
      (confidence, confidence >= threshold && !clues.contested)
    }
  }
  Some({ lang, script, confidence, reliable, margin, runner_up, })
}
