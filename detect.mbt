///|
/// Why `Options::new` rejected its arguments.
pub(all) suberror OptionsError {
  /// `allow` was given but empty, so no language could ever match.
  EmptyAllow
  /// The language is both allowed and denied.
  AllowDenyOverlap(Lang)
  /// `deny` lists every language, so no language could ever match.
  DenyAll
  /// `min_length` must not be negative.
  NegativeMinLength(Int)
} derive(Eq, Debug)

///|
/// Settings for `detect` and `rank`. Build with `Options::new`.
pub struct Options {
  allow : Array[Lang]
  deny : Array[Lang]
  min_length : Int
}

///|
/// Restricts detection to `allow` (when given) and never returns a
/// language in `deny`. Texts shorter than `min_length` UTF-16 code units
/// are not identified. Contradictory settings raise an error instead of
/// being ignored.
pub fn Options::new(
  allow? : Array[Lang],
  deny? : Array[Lang] = [],
  min_length? : Int = 10,
) -> Options raise OptionsError {
  if min_length < 0 {
    raise NegativeMinLength(min_length)
  }
  let allow = match allow {
    Some([]) => raise EmptyAllow
    Some(langs) => langs.copy()
    None => []
  }
  for lang in allow {
    if deny.contains(lang) {
      raise AllowDenyOverlap(lang)
    }
  }
  if all_langs.iter().all(lang => deny.contains(lang)) {
    raise DenyAll
  }
  { allow, deny: deny.copy(), min_length, }
}

///|
let default_options : Options = { allow: [], deny: [], min_length: 10, }

///|
/// The languages allowed by these options, empty when all are.
pub fn Options::allow(self : Options) -> Array[Lang] {
  self.allow.copy()
}

///|
/// The languages excluded by these options.
pub fn Options::deny(self : Options) -> Array[Lang] {
  self.deny.copy()
}

///|
/// Minimum text length, in UTF-16 code units, for a detection.
pub fn Options::min_length(self : Options) -> Int {
  self.min_length
}

///|
/// Result of `detect`.
///
/// `confidence` is the margin between the best and the second-best
/// language on franc's normalised scale (1.0 when there is no second
/// candidate). `reliable` is true when `confidence` is at least
/// `reliable_min_margin` and the text is at least `reliable_min_length`
/// UTF-16 code units long.
pub(all) struct Detection {
  lang : Lang
  script : Script
  confidence : Double
  reliable : Bool
} derive(Eq, Debug)

///|
/// Minimum `confidence` for a reliable detection.
pub let reliable_min_margin : Double = 0.15

///|
/// Minimum text length, in UTF-16 code units, for a reliable detection.
pub let reliable_min_length : Int = 30

///|
/// Candidate languages with scores between 0 and 1, best first, as
/// franc-min 6.2.0 ranks them: the best language scores 1.0 and the others
/// are scaled by their trigram distance relative to it. Ties keep a fixed
/// language order. Returns an empty array when the text is shorter than
/// `min_length` or contains no letters of a supported script.
pub fn rank(
  text : String,
  options? : Options = default_options,
) -> Array[(Lang, Double)] {
  match franc_all(text, options.allow, options.deny, options.min_length) {
    Some((_, ranked)) => ranked
    None => []
  }
}

///|
/// The most likely language of `text`, or `None` when the text is shorter
/// than `min_length` or contains no letters of a supported script (empty,
/// whitespace, digits, punctuation or emoji). Never guesses.
pub fn detect(
  text : String,
  options? : Options = default_options,
) -> Detection? {
  guard franc_all(text, options.allow, options.deny, options.min_length)
    is Some((script, ranked)) else {
    return None
  }
  let confidence = if ranked.length() > 1 {
    ranked[0].1 - ranked[1].1
  } else {
    1.0
  }
  let reliable = confidence >= reliable_min_margin &&
    text.length() >= reliable_min_length
  Some({ lang: ranked[0].0, script, confidence, reliable, })
}
