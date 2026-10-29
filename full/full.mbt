// franc 6.2.0 with all of its languages, for applications that need more
// than franc-min's: 186 as franc counts them (once per script), 178 ISO
// 639-3 codes. Languages are those codes, since most of them have no
// `@mbglot.Lang`.

///|
/// franc's limit on the text it looks at, in UTF-16 code units.
let max_sample_length : Int32 = 2048

///|
/// The profiles of each trigram script, in franc's order.
let script_profiles : Map[String, Array[@mbglot.Profile]] = {
  let out = Map([])
  for entry in profiles {
    let (script, languages) = entry
    out[script] = languages
      .iter()
      .map(language => {
        let (code, model) = language
        let saved = "mbglot profile 1\n\{code}\n" +
          model.split("|").map(gram => gram.to_owned()).collect().join("\n")
        @mbglot.Profile::parse(saved) catch {
          _ => abort("bad profile for \{code}")
        }
      })
      .collect()
  }
  out
}

///|
/// A classifier per trigram script with every language, built when first
/// needed.
let classifiers : Map[String, @mbglot.Classifier] = Map([])

///|
fn in_ranges(ranges : FixedArray[Int32], cp : Int32) -> Bool {
  let mut lo = 0
  let mut hi = ranges.length() / 2 - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    if cp < ranges[2 * mid] {
      hi = mid - 1
    } else if cp > ranges[2 * mid + 1] {
      lo = mid + 1
    } else {
      return true
    }
  }
  false
}

///|
/// The key of `scripts` with the most code points in `sample`, ties to the
/// first, and its count. A surrogate pair counts as its code point and an
/// unpaired surrogate as nothing, as franc's regular expressions do.
fn top_script(sample : String) -> (String, Int32) {
  let counts = FixedArray::make(scripts.length(), 0)
  let mut i = 0
  while i < sample.length() {
    let unit = sample.unsafe_get(i).to_int()
    let mut cp = -1
    if unit >= 0xD800 && unit <= 0xDBFF && i + 1 < sample.length() {
      let next = sample.unsafe_get(i + 1).to_int()
      if next >= 0xDC00 && next <= 0xDFFF {
        cp = 0x10000 + ((unit - 0xD800) << 10) + (next - 0xDC00)
        i += 1
      }
    } else if unit < 0xD800 || unit > 0xDFFF {
      cp = unit
    }
    i += 1
    if cp < 0 {
      continue
    }
    for s, entry in scripts {
      if in_ranges(entry.1, cp) {
        counts[s] += 1
      }
    }
  }
  let mut best = 0
  for s in 1..<counts.length() {
    if counts[s] > counts[best] {
      best = s
    }
  }
  (scripts[best].0, counts[best])
}

///|
fn allowed(code : String, allow : Array[String], deny : Array[String]) -> Bool {
  (allow.is_empty() || allow.contains(code)) && !deny.contains(code)
}

///|
/// The result of franc 6.2.0's `francAll`: ISO 639-3 codes with scores
/// between 0 and 1, best first, or `[("und", 1.0)]` when the text is
/// shorter than `min_length` UTF-16 code units, has no letters of a
/// supported script, or every candidate is excluded. `allow` and `deny`
/// are franc's `only` and `ignore`. A golden test checks the results
/// against franc on its own fixtures.
pub fn franc_all(
  text : String,
  allow~ : Array[String] = [],
  deny~ : Array[String] = [],
  min_length~ : Int32 = 10,
) -> Array[(String, Double)] {
  let und = [("und", 1.0)]
  if text.length() == 0 || text.length() < min_length {
    return und
  }
  let sample = if text.length() > max_sample_length {
    text.view(end_offset=max_sample_length).to_owned()
  } else {
    text
  }
  let (script, count) = top_script(sample)
  guard script_profiles.get(script) is Some(candidates) else {
    return if count == 0 || !allowed(script, allow, deny) {
      und
    } else {
      [(script, 1.0)]
    }
  }
  let classifier = if allow.is_empty() && deny.is_empty() {
    match classifiers.get(script) {
      Some(c) => c
      None => {
        let c = @mbglot.Classifier::new(candidates) catch {
          _ => abort("no profiles for \{script}")
        }
        classifiers[script] = c
        c
      }
    }
  } else {
    let kept = candidates.filter(p => allowed(p.name(), allow, deny))
    if kept.is_empty() {
      return und
    }
    // Not empty, and the names are distinct.
    @mbglot.Classifier::new(kept) catch {
      _ => abort("unreachable")
    }
  }
  match classifier.rank(sample, min_length=0) {
    [] => und
    ranked => ranked
  }
}

///|
/// The most likely language of `text` as an ISO 639-3 code, or `"und"`;
/// franc's `franc`.
pub fn franc(
  text : String,
  allow~ : Array[String] = [],
  deny~ : Array[String] = [],
  min_length~ : Int32 = 10,
) -> String {
  franc_all(text, allow~, deny~, min_length~)[0].0
}

///|
/// Every language franc can return, as ISO 639-3 codes, sorted.
pub fn languages() -> Array[String] {
  let codes : Set[String] = Set([])
  for entry in scripts {
    if script_profiles.get(entry.0) is None {
      codes.add(entry.0)
    }
  }
  for entry in profiles {
    for language in entry.1 {
      codes.add(language.0)
    }
  }
  let out = codes.to_array()
  out.sort()
  out
}
