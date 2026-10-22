///|
/// Distance added for a trigram missing from a profile.
let max_difference : Int32 = 300

///|
/// Profiles of the trigram scripts as trigram -> rank maps, built once.
let numeric_profiles : FixedArray[
  (Script, FixedArray[(Lang, Map[String, Int32])]),
] = trigram_profiles.map(entry => {
  let langs = entry.1.map(profile => {
    let ranks : Map[String, Int32] = Map([])
    for i, gram in profile.1.split("|").collect() {
      ranks[gram.to_owned()] = i
    }
    (profile.0, ranks)
  })
  (entry.0, langs)
})

///|
fn allowed(lang : Lang, allow : Array[Lang], deny : Array[Lang]) -> Bool {
  (allow.is_empty() || allow.contains(lang)) && !deny.contains(lang)
}

///|
fn distance(
  trigrams : Array[(String, Int32)],
  model : Map[String, Int32],
) -> Int32 {
  let mut total = 0
  for tuple in trigrams {
    total += match model.get(tuple.0) {
      Some(rank) => {
        let diff = tuple.1 - rank - 1
        if diff < 0 {
          -diff
        } else {
          diff
        }
      }
      None => max_difference
    }
  }
  total
}

///|
/// Result of franc's `francAll`, without the `und` entry: the script that
/// decided the outcome and the languages with normalised scores, best
/// first. `None` where franc returns `und`.
fn franc_all(
  text : String,
  allow : Array[Lang],
  deny : Array[Lang],
  min_length : Int32,
) -> (Script, Array[(Lang, Double)])? {
  if text.length() == 0 || text.length() < min_length {
    return None
  }
  let (index, _) = top_script(text)
  if index < 0 {
    return None
  }
  let script = all_scripts[index]
  if script.sole_language() is Some(lang) {
    return if allowed(lang, allow, deny) {
      Some((script, [(lang, 1.0)]))
    } else {
      None
    }
  }
  let sample = if text.length() > max_sample_length {
    text.view(end_offset=max_sample_length).to_owned()
  } else {
    text
  }
  let grams = trigrams(sample)
  let distances : Array[(Lang, Int32, Int32)] = []
  for entry in numeric_profiles {
    if entry.0 != script {
      continue
    }
    for profile in entry.1 {
      if allowed(profile.0, allow, deny) {
        distances.push(
          (profile.0, distance(grams, profile.1), distances.length()),
        )
      }
    }
  }
  if distances.is_empty() {
    return None
  }
  distances.sort_by((a, b) => if a.1 != b.1 { a.1 - b.1 } else { a.2 - b.2 })
  let min = distances[0].1
  let max = sample.length() * max_difference - min
  let ranked = distances.map(d => {
    let score = 1.0 - (d.1 - min).to_double() / max.to_double()
    (d.0, if score.is_nan() { 0.0 } else { score })
  })
  Some((script, ranked))
}
