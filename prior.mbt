///|
/// How far behind the best score a related language may be for the prior
/// to consider it.
let tie_window : Double = 0.12

///|
/// What a tenfold larger number of speakers adds to a score when breaking
/// a near tie. Chosen with `tie_window` on the dev half of the Tatoeba
/// benchmark, whose languages are equally frequent; with real traffic the
/// larger language is likelier still.
///
/// Hindi, Bhojpuri, Maithili and Magahi are left out: on the FLORES-200
/// dev set, where the four are equally frequent, a pull toward Hindi cost
/// more than it gained on Tatoeba, which has no Magahi.
let speakers_weight : Double = 0.1

///|
/// The languages related to `lang`: its group in `groups`. Empty when
/// there is none.
fn related(lang : Lang) -> Array[Lang] {
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
  words : Map[String, Int32],
  ranked : Array[(Lang, Double)],
) -> Array[(Lang, Double)] {
  guard ranked.length() > 1 else { return ranked }
  let top = ranked[0]
  let family = related(top.0)
  if family.is_empty() || clues(words, top.0, Some(ranked[1].0)).evidence > 0 {
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
