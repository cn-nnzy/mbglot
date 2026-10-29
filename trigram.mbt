///|
/// Whitespace as matched by `\s` in JavaScript regular expressions.
fn is_js_space(unit : Int32) -> Bool {
  match unit {
    0x09..<=0x0D | 0x20 | 0xA0 | 0x1680 | 0x2000..<=0x200A => true
    0x2028 | 0x2029 | 0x202F | 0x205F | 0x3000 | 0xFEFF => true
    _ => false
  }
}

///|
fn lower_simple(cp : Int32) -> Int32 {
  let mut lo = 0
  let mut hi = lower_from.length() - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    let key = lower_from[mid]
    if cp < key {
      hi = mid - 1
    } else if cp > key {
      lo = mid + 1
    } else {
      return lower_to[mid]
    }
  }
  cp
}

///|
fn decode_utf16(units : Array[Int32]) -> Array[Int32] {
  let out = []
  let mut i = 0
  while i < units.length() {
    let unit = units[i]
    if unit >= 0xD800 &&
      unit <= 0xDBFF &&
      i + 1 < units.length() &&
      units[i + 1] >= 0xDC00 &&
      units[i + 1] <= 0xDFFF {
      out.push(0x10000 + ((unit - 0xD800) << 10) + (units[i + 1] - 0xDC00))
      i += 2
    } else {
      out.push(unit)
      i += 1
    }
  }
  out
}

///|
fn push_utf16(out : Array[Int32], cp : Int32) -> Unit {
  if cp >= 0x10000 {
    let v = cp - 0x10000
    out.push(0xD800 + (v >> 10))
    out.push(0xDC00 + (v & 0x3FF))
  } else {
    out.push(cp)
  }
}

///|
/// Unicode Final_Sigma condition for the capital sigma at `index`, with
/// case-ignorable characters taking precedence over cased ones as in ICU.
fn is_final_sigma(cps : Array[Int32], index : Int32) -> Bool {
  let mut before = false
  let mut i = index - 1
  while i >= 0 {
    let cp = cps[i]
    if in_ranges(case_ignorable_ranges, cp) {
      i -= 1
      continue
    }
    before = in_ranges(cased_ranges, cp)
    break
  }
  if !before {
    return false
  }
  let mut j = index + 1
  while j < cps.length() {
    let cp = cps[j]
    if in_ranges(case_ignorable_ranges, cp) {
      j += 1
      continue
    }
    return !in_ranges(cased_ranges, cp)
  }
  true
}

///|
/// Full lowercasing as done by JavaScript's `toLowerCase` (root locale),
/// on UTF-16 code units. Unpaired surrogates are kept.
fn lowercase(units : Array[Int32]) -> Array[Int32] {
  let cps = decode_utf16(units)
  let out = []
  for i, cp in cps {
    match cp {
      0x130 => {
        out.push(0x69)
        out.push(0x307)
      }
      0x3A3 => out.push(if is_final_sigma(cps, i) { 0x3C2 } else { 0x3C3 })
      _ => push_utf16(out, lower_simple(cp))
    }
  }
  out
}

///|
/// trigram-utils `clean`: runs of U+0021..U+0040 and whitespace become a
/// single space, the ends are trimmed and the result is lowercased.
fn clean_units(text : String) -> Array[Int32] {
  let units = []
  let mut pending_space = false
  for i in 0..<text.length() {
    let unit = text.unsafe_get(i).to_int()
    if (unit >= 0x21 && unit <= 0x40) || is_js_space(unit) {
      pending_space = true
    } else {
      if pending_space && units.length() > 0 {
        units.push(0x20)
      }
      pending_space = false
      units.push(unit)
    }
  }
  lowercase(units)
}

///|
/// Three UTF-16 code units packed into one integer, first unit highest.
fn pack(a : Int32, b : Int32, c : Int32) -> Int64 {
  (a.to_int64() << 32) | (b.to_int64() << 16) | c.to_int64()
}

///|
/// The trigram string `gram` (three UTF-16 code units) as a key.
fn key_of(gram : StringView) -> Int64 {
  pack(
    gram.unsafe_get(0).to_int(),
    gram.unsafe_get(1).to_int(),
    gram.unsafe_get(2).to_int(),
  )
}

///|
/// trigram-utils `asTuples` with each trigram as a key made by `pack`:
/// trigrams of UTF-16 code units of the cleaned text padded with one space
/// on each side, with their counts, ordered by ascending count and then by
/// first occurrence.
fn trigram_keys(text : String) -> Array[(Int64, Int32)] {
  let units = [0x20]
  units.append(clean_units(text))
  units.push(0x20)
  let counts : Map[Int64, Int32] = Map([])
  for i in 0..<(units.length() - 2) {
    let key = pack(units[i], units[i + 1], units[i + 2])
    counts[key] = counts.get_or_default(key, 0) + 1
  }
  let indexed = counts.to_array().mapi((i, t) => (t.0, t.1, i))
  indexed.sort_by((a, b) => if a.1 != b.1 { a.1 - b.1 } else { a.2 - b.2 })
  indexed.map(t => (t.0, t.1))
}
