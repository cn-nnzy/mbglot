///|
/// Distance added for a trigram missing from a profile.
let max_difference : Int32 = 300

///|
/// The trigram profiles of one script, inverted: for each trigram, the
/// languages whose profile has it and its rank there.
priv struct ScriptIndex {
  script : Script
  /// The script's languages in franc-min's order.
  langs : FixedArray[Lang]
  /// Trigram key (see `pack`) -> (position in `langs`, rank) pairs.
  postings : Map[Int64, Array[(Int32, Int32)]]
}

///|
/// One index per trigram script, built once. A text trigram is looked up
/// once for all languages, instead of once per language.
let script_indexes : FixedArray[ScriptIndex] = trigram_profiles.map(entry => {
  let postings : Map[Int64, Array[(Int32, Int32)]] = Map([])
  for i, profile in entry.1 {
    for rank, gram in profile.1.split("|").collect() {
      let key = key_of(gram)
      match postings.get(key) {
        Some(list) => list.push((i, rank))
        None => postings[key] = [(i, rank)]
      }
    }
  }
  { script: entry.0, langs: entry.1.map(profile => profile.0), postings, }
})

///|
fn allowed(lang : Lang, allow : Array[Lang], deny : Array[Lang]) -> Bool {
  (allow.is_empty() || allow.contains(lang)) && !deny.contains(lang)
}

///|
/// Which languages of each script index `allow` and `deny` leave, in the
/// order of `script_indexes`.
fn language_masks(
  allow : Array[Lang],
  deny : Array[Lang],
) -> FixedArray[FixedArray[Bool]] {
  script_indexes.map(index => {
    index.langs.map(lang => allowed(lang, allow, deny))
  })
}

///|
/// franc's trigram distance from the text's trigrams to every language of
/// `index`: for each trigram of the text, the difference between its count
/// and its rank in the profile, or `max_difference` when the profile lacks
/// it, summed.
fn distances(
  grams : Map[Int64, Int32],
  index : ScriptIndex,
) -> FixedArray[Int32] {
  let totals = FixedArray::make(
    index.langs.length(),
    grams.length() * max_difference,
  )
  for key, count in grams {
    guard index.postings.get(key) is Some(list) else { continue }
    for posting in list {
      let (i, rank) = posting
      let diff = count - rank - 1
      totals[i] += (if diff < 0 { -diff } else { diff }) - max_difference
    }
  }
  totals
}

///|
/// Result of franc's `francAll`, without the `und` entry: the script that
/// decided the outcome and the languages with normalised scores, best
/// first, for the text that `stats` describe. `None` where franc returns
/// `und`. `masks` are the languages that `allow` and `deny` leave, per
/// script index (see `language_masks`).
fn franc_masked(
  stats : TextStats,
  allow : Array[Lang],
  deny : Array[Lang],
  masks : FixedArray[FixedArray[Bool]],
  min_length : Int32,
) -> (Script, Array[(Lang, Double)])? {
  if stats.length == 0 || stats.length < min_length {
    return None
  }
  let top = stats.top_script()
  if top < 0 {
    return None
  }
  let script = all_scripts[top]
  if script.sole_language() is Some(lang) {
    return if allowed(lang, allow, deny) {
      Some((script, [(lang, 1.0)]))
    } else {
      None
    }
  }
  let found : Array[(Lang, Int32, Int32)] = []
  for k, index in script_indexes {
    if index.script != script {
      continue
    }
    let mask = masks[k]
    let totals = distances(stats.grams, index)
    for i, lang in index.langs {
      if mask[i] {
        found.push((lang, totals[i], found.length()))
      }
    }
  }
  if found.is_empty() {
    return None
  }
  found.sort_by((a, b) => if a.1 != b.1 { a.1 - b.1 } else { a.2 - b.2 })
  let min = found[0].1
  let max = stats.sample_length * max_difference - min
  let ranked = found.map(d => {
    let score = 1.0 - (d.1 - min).to_double() / max.to_double()
    (d.0, if score.is_nan() { 0.0 } else { score })
  })
  Some((script, ranked))
}
