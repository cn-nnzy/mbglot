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
/// The benchmark samples of the given length, or of every length.
pub fn samples(length? : Length) -> Array[@eval.Sample] {
  let out = []
  for row in rows {
    let (lang, len, _, text) = row
    if length is Some(l) && l != len {
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
