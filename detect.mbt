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
  NegativeMinLength(Int32)
} derive(Eq, Debug)

///|
/// Settings for `detect` and `rank`. Build with `Options::new`.
pub struct Options {
  allow : Array[Lang]
  deny : Array[Lang]
  min_length : Int32
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
  deny~ : Array[Lang] = [],
  min_length~ : Int32 = 10,
  mode~ : Mode = Enhanced,
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
pub fn Options::min_length(self : Options) -> Int32 {
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
/// `margin` is the margin between the best and the second-best language
/// on franc's normalised scale (1.0 when there is no second candidate),
/// and `runner_up` that second language. `confidence` is the margin in
/// `Mode::Franc`; in `Mode::Enhanced` it adds `evidence_weight` for every
/// letter or common word that points to `lang` rather than the runner-up,
/// up to 1.0. It is a score for ordering and thresholds, not a
/// probability. `reliable` says whether the detection can be acted on
/// without review (see `reliable_min_margin` for `Mode::Franc` and
/// `reliable_min_confidence` for `Mode::Enhanced`).
pub(all) struct Detection {
  lang : Lang
  script : Script
  confidence : Double
  reliable : Bool
  margin : Double
  runner_up : Lang?
} derive(Eq, Debug)

///|
/// Minimum margin for a reliable detection in `Mode::Franc`.
pub let reliable_min_margin : Double = 0.15

///|
/// Minimum text length, in UTF-16 code units, for a reliable detection in
/// `Mode::Franc`. In `Mode::Enhanced` shorter texts need a higher
/// confidence instead (`short_reliable_min_confidence`).
pub let reliable_min_length : Int32 = 30

///|
/// What one letter or common word adds to `confidence` in
/// `Mode::Enhanced`. Chosen with the two thresholds below on the dev half
/// of the Tatoeba benchmark.
let evidence_weight : Double = 0.04

///|
/// Minimum `confidence` for a reliable detection in `Mode::Enhanced`, for
/// texts of at least `reliable_min_length` UTF-16 code units.
pub let reliable_min_confidence : Double = 0.18

///|
/// Minimum `confidence` for a reliable detection in `Mode::Enhanced`, for
/// texts shorter than `reliable_min_length`.
pub let short_reliable_min_confidence : Double = 0.4

///|
/// franc's result for the text `stats` describe under `options`, followed in `Enhanced` mode
/// by the pass for closely related languages. `masks` are the languages
/// `options` leave (see `language_masks`).
fn ranking(
  stats : TextStats,
  options : Options,
  masks : FixedArray[FixedArray[Bool]],
  steps? : Array[Step],
) -> (Script, Array[(Lang, Double)])? {
  guard franc_masked(
      stats,
      options.allow,
      options.deny,
      masks,
      options.min_length,
    )
    is Some((script, ranked)) else {
    return None
  }
  let record = (step : Step) => if steps is Some(list) { list.push(step) }
  record(Trigrams(ranked[0].0))
  match options.mode {
    Franc => Some((script, ranked))
    Enhanced => {
      let before = ranked[0].0
      let (script, ranked) = refine_cjk(
        stats,
        script,
        ranked,
        options.allow,
        options.deny,
      )
      if ranked[0].0 != before {
        record(ScriptShare(ranked[0].0))
      }
      let before = ranked[0].0
      let ranked = short_text_signal(stats, ranked)
      if ranked[0].0 != before {
        record(
          CommonWords(ranked[0].0, common_words_of(ranked[0].0, stats.words)),
        )
      }
      let before = ranked[0].0
      let ranked = settle_confusables(
        stats,
        ranked,
        options.allow,
        options.deny,
        script~,
      )
      if ranked[0].0 != before {
        record(
          RelatedLanguages(
            ranked[0].0,
            group_clues(ranked[0].0, before, stats.words, script),
          ),
        )
      }
      let before = ranked[0].0
      let ranked = near_tie_prior(stats.words, ranked, script~)
      if ranked[0].0 != before {
        record(NearTie(ranked[0].0, before))
      }
      Some((script, ranked))
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
/// Russian, Ukrainian, Belarusian, Bulgarian, Serbian, Kazakh or Bosnian
/// in Cyrillic script; Croatian, Serbian or Bosnian in Latin script;
/// Indonesian or Malay; Rundi or Kinyarwanda; Tagalog or Cebuano; Hausa
/// or Nigerian Fulfulde; Javanese or Sundanese; or the languages written
/// in Arabic script), that language
/// moves to the top and swaps scores with franc's choice. Returns an empty
/// array when the text is shorter than `min_length` or contains no letters
/// of a supported script.
pub fn rank(
  text : String,
  options~ : Options = default_options,
) -> Array[(Lang, Double)] {
  detector_for(options).rank(text)
}

///|
/// The most likely language of `text`, or `None` when the text is shorter
/// than `min_length` or contains no letters of a supported script (empty,
/// whitespace, digits, punctuation or emoji). Never guesses.
pub fn detect(
  text : String,
  options~ : Options = default_options,
) -> Detection? {
  detector_for(options).detect(text)
}
