///|
/// Text length class of a benchmark sample, in UTF-16 code units.
pub(all) enum Length {
  /// One sentence of 10 to 30 code units.
  Short
  /// One sentence of 31 to 80 code units.
  Medium
  /// Several sentences joined, at least 150 code units.
  Long
} derive(Eq, Hash, Debug)

///|
pub fn Length::all() -> Array[Length] {
  [Short, Medium, Long]
}

///|
pub fn Length::name(self : Length) -> String {
  match self {
    Short => "short"
    Medium => "medium"
    Long => "long"
  }
}

///|
/// Every corpus entry, language by language: language, length, Tatoeba
/// sentence ids, text.
let rows : Array[(@mbglot.Lang, Length, Array[Int32], String)] = {
  let all = []
  for table in tables {
    all.append(table)
  }
  all
}

///|
/// Half of the corpus. Within each language and length the samples
/// alternate between the two, in the corpus's SHA-256 order, so both halves
/// have the same mix and neither depends on how the other is used.
pub(all) enum Split {
  /// For choosing weights and thresholds.
  Dev
  /// Held out: only for reporting.
  Test
} derive(Eq, Debug)

///|
pub fn Split::name(self : Split) -> String {
  match self {
    Dev => "dev"
    Test => "test"
  }
}

///|
/// The benchmark samples of the given length and split, or of every
/// length and both splits when they are not given.
pub fn samples(length? : Length, split? : Split) -> Array[@eval.Sample] {
  let out = []
  let seen : Map[(@mbglot.Lang, Length), Int32] = Map([])
  for row in rows {
    let (lang, len, _, text) = row
    let index = seen.get((lang, len)).unwrap_or(0)
    seen[(lang, len)] = index + 1
    if length is Some(l) && l != len {
      continue
    }
    let half = if index % 2 == 0 { Dev } else { Test }
    if split is Some(s) && s != half {
      continue
    }
    out.push(@eval.Sample::{ lang, text, })
  }
  out
}

///|
/// The languages that have benchmark samples, in `Lang::all()` order.
pub fn languages() -> Array[@mbglot.Lang] {
  let present : Set[@mbglot.Lang] = Set([])
  for row in rows {
    present.add(row.0)
  }
  @mbglot.Lang::all().filter(lang => present.contains(lang))
}
