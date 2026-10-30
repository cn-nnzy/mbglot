///|
/// Every corpus entry, language by language: language, position in the
/// FLORES-200 devtest files, text.
let rows : Array[(@mbglot.Lang, Int32, String)] = {
  let all = []
  for table in tables {
    all.append(table)
  }
  all
}

///|
/// The benchmark samples: the same 40 FLORES-200 devtest sentences in
/// each language, translated from English news and travel articles.
pub fn samples() -> Array[@eval.Sample] {
  rows.map(row => @eval.Sample::{ lang: row.0, text: row.2, })
}

///|
/// The languages that have samples, in `Lang::all()` order.
pub fn languages() -> Array[@mbglot.Lang] {
  let present : Set[@mbglot.Lang] = Set([])
  for row in rows {
    present.add(row.0)
  }
  @mbglot.Lang::all().filter(lang => present.contains(lang))
}
