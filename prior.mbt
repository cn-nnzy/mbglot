///|
/// How far behind the best score a related language may be for the prior
/// to consider it.
let tie_window : Double = 0.12

///|
/// What a tenfold larger number of speakers adds to a score when breaking
/// a near tie. Chosen with `tie_window` on the dev half of the Tatoeba
/// benchmark, whose languages are equally frequent; with real traffic the
/// larger language is likelier still.
let speakers_weight : Double = 0.1

///|
/// Hindi and the languages of the Hindi belt, which franc-min ranks close
/// together but no rule of `groups` separates.
let hindi_belt : Array[Lang] = [Hin, Bho, Mai, Mag]

///|
/// The languages related to `lang`: its group in `groups`, or the Hindi
/// belt. Empty when there are none.
fn related(lang : Lang) -> Array[Lang] {
  if hindi_belt.contains(lang) {
    return hindi_belt
  }
  for group in groups {
    if group.langs.contains(lang) {
      return group.langs
    }
  }
  []
}

///|
/// The ranking after the near-tie prior. When the text has no letters or
/// words that favour franc's best language over the runner-up, a related
/// language within `tie_window` of the best score may take first place:
/// each such candidate's score gets `speakers_weight` times the
/// logarithm of its number of speakers, and the highest total wins (see
/// `promote`). Unrelated languages and languages further behind are never
/// moved.
fn near_tie_prior(
  text : String,
  ranked : Array[(Lang, Double)],
) -> Array[(Lang, Double)] {
  guard ranked.length() > 1 else { return ranked }
  let top = ranked[0]
  let family = related(top.0)
  if family.is_empty() || clues(text, top.0, Some(ranked[1].0)).evidence > 0 {
    return ranked
  }
  let mut best = top.0
  let mut best_total = top.1 +
    speakers_weight * @math.log10(top.0.speakers().to_double())
  for entry in ranked[1:] {
    let (lang, score) = entry
    if top.1 - score > tie_window {
      break
    }
    if !family.contains(lang) {
      continue
    }
    let total = score +
      speakers_weight * @math.log10(lang.speakers().to_double())
    if total > best_total {
      best = lang
      best_total = total
    }
  }
  promote(ranked, best)
}
