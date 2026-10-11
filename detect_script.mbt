///|
/// franc only looks at this many UTF-16 code units of the input.
let max_sample_length : Int = 2048

///|
fn in_ranges(ranges : FixedArray[Int], cp : Int) -> Bool {
  let mut lo = 0
  let mut hi = ranges.length() / 2 - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    if cp < ranges[mid * 2] {
      hi = mid - 1
    } else if cp > ranges[mid * 2 + 1] {
      lo = mid + 1
    } else {
      return true
    }
  }
  false
}

///|
/// Counts, per script, the code points of the first `max_sample_length`
/// code units of `text`. A surrogate pair cut by the limit and unpaired
/// surrogates count for no script, as in franc's regular expressions.
fn script_counts(text : String) -> FixedArray[Int] {
  let counts = FixedArray::make(script_ranges.length(), 0)
  let limit = if text.length() < max_sample_length {
    text.length()
  } else {
    max_sample_length
  }
  let mut i = 0
  while i < limit {
    let unit = text.unsafe_get(i).to_int()
    let mut cp = -1
    if unit >= 0xD800 && unit <= 0xDBFF && i + 1 < limit {
      let next = text.unsafe_get(i + 1).to_int()
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
    for s in 0..<script_ranges.length() {
      if in_ranges(script_ranges[s], cp) {
        counts[s] += 1
      }
    }
  }
  counts
}

///|
/// Index into `all_scripts` of the most frequent script and its count.
/// Ties go to the script listed first. The index is -1 when no character
/// belongs to any script.
fn top_script(text : String) -> (Int, Int) {
  let counts = script_counts(text)
  let mut best = -1
  let mut best_count = 0
  for s in 0..<counts.length() {
    if counts[s] > best_count {
      best = s
      best_count = counts[s]
    }
  }
  (best, best_count)
}

///|
/// The writing system used by most characters of `text`, following
/// franc-min 6.2.0: only the first 2048 UTF-16 code units are examined,
/// and ties go to the script listed first in `Script::all()`. Returns
/// `None` when no character belongs to a supported script, e.g. for empty
/// input, digits, punctuation or emoji.
///
/// A character can belong to more than one script: Han ideographs count
/// for both `Han` and `Kana`, so Chinese text is `Han` (the tie goes to
/// `Han`) while Japanese text mixing kana and kanji is `Kana`.
pub fn detect_script(text : String) -> Script? {
  match top_script(text) {
    (-1, _) => None
    (index, _) => Some(all_scripts[index])
  }
}
