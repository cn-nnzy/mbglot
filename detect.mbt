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
  strip_markup : Bool
  mode : Mode
}

///|
/// Restricts detection to `allow` (when given) and never returns a
/// language in `deny`. Texts shorter than `min_length` UTF-16 code units
/// are not identified. `mode` chooses between franc's ranking alone
/// (`Franc`) and franc's ranking with a second pass for closely related
/// languages (`Enhanced`, the default). With `strip_markup`, which
/// defaults to true in `Enhanced` mode and false in `Franc` mode, URLs,
/// e-mail addresses, mentions, hashtags, HTML and code are removed before
/// detection (see `strip_markup`), and `min_length` applies to what is
/// left. Contradictory settings raise an error instead of being ignored.
pub fn Options::new(
  allow? : Array[Lang],
  deny? : Array[Lang] = [],
  min_length? : Int = 10,
  mode? : Mode = Enhanced,
  strip_markup? : Bool,
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
  let strip_markup = strip_markup.unwrap_or(mode == Enhanced)
  { allow, deny: deny.copy(), min_length, strip_markup, mode, }
}

///|
let default_options : Options = {
  allow: [],
  deny: [],
  min_length: 10,
  strip_markup: true,
  mode: Enhanced,
}

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
/// Whether markup is removed before detection.
pub fn Options::strip_markup(self : Options) -> Bool {
  self.strip_markup
}

///|
/// How languages are decided.
pub fn Options::mode(self : Options) -> Mode {
  self.mode
}

///|
/// The text that is identified: `text` without markup when the options
/// say so.
fn prepared(text : String, options : Options) -> String {
  if options.strip_markup {
    strip_markup(text).text
  } else {
    text
  }
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
/// franc's result for `text` under `options`, followed in `Enhanced` mode
/// by the pass for closely related languages.
fn ranking(
  text : String,
  options : Options,
) -> (Script, Array[(Lang, Double)])? {
  guard franc_all(text, options.allow, options.deny, options.min_length)
    is Some((script, ranked)) else {
    return None
  }
  match options.mode {
    Franc => Some((script, ranked))
    Enhanced => {
      let ranked = short_text_signal(text, ranked)
      Some(
        (script, settle_confusables(text, ranked, options.allow, options.deny)),
      )
    }
  }
}

///|
/// Candidate languages with scores between 0 and 1, best first. The
/// scores are franc-min 6.2.0's: the best language scores 1.0 and the
/// others are scaled by their trigram distance relative to it, ties in a
/// fixed language order. In `Franc` mode the ranking is franc's. In
/// `Enhanced` mode, when the letters and common words of the text show
/// that a closely related language is meant (Spanish or Portuguese;
/// Russian, Ukrainian, Belarusian, Bulgarian, Serbian or Kazakh; Croatian,
/// Serbian or Bosnian; Indonesian or Malay; Rundi or Kinyarwanda; Tagalog
/// or Cebuano; or the languages written in Arabic script), that language
/// moves to the top and swaps scores with franc's choice. Returns an empty
/// array when the text is shorter than `min_length` or contains no letters
/// of a supported script.
pub fn rank(
  text : String,
  options? : Options = default_options,
) -> Array[(Lang, Double)] {
  match ranking(prepared(text, options), options) {
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
  let text = prepared(text, options)
  guard ranking(text, options) is Some((script, ranked)) else { return None }
  let confidence = if ranked.length() > 1 {
    ranked[0].1 - ranked[1].1
  } else {
    1.0
  }
  let reliable = confidence >= reliable_min_margin &&
    text.length() >= reliable_min_length
  Some({ lang: ranked[0].0, script, confidence, reliable, })
}
