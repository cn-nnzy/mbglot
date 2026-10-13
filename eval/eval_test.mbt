///|
/// A predictor that answers from a fixed table of text to language.
fn table_predictor(
  table : Array[(String, @mbglot.Lang?)],
) -> (String) -> @mbglot.Lang? {
  text => {
    for entry in table {
      if entry.0 == text {
        return entry.1
      }
    }
    None
  }
}

///|
/// Five Spanish, three Portuguese and two English samples: one Spanish
/// text read as Portuguese, two Portuguese texts read as Spanish and one
/// English text left unidentified.
fn sample_report() -> @eval.Report {
  let samples : Array[@eval.Sample] = [
    { lang: Spa, text: "s1", },
    { lang: Spa, text: "s2", },
    { lang: Spa, text: "s3", },
    { lang: Spa, text: "s4", },
    { lang: Spa, text: "s5", },
    { lang: Por, text: "p1", },
    { lang: Por, text: "p2", },
    { lang: Por, text: "p3", },
    { lang: Eng, text: "e1", },
    { lang: Eng, text: "e2", },
  ]
  let table : Array[(String, @mbglot.Lang?)] = [
    ("s1", Some(Spa)),
    ("s2", Some(Spa)),
    ("s3", Some(Spa)),
    ("s4", Some(Spa)),
    ("s5", Some(Por)),
    ("p1", Some(Spa)),
    ("p2", Some(Spa)),
    ("p3", Some(Por)),
    ("e1", Some(Eng)),
    ("e2", None),
  ]
  @eval.evaluate(samples, table_predictor(table))
}

///|
test "totals and accuracy" {
  let report = sample_report()
  assert_eq(report.total(), 10)
  assert_eq(report.correct(), 6)
  assert_eq(report.unidentified(), 1)
  assert_eq(report.accuracy(), 0.6)
  assert_eq(report.languages(), [Spa, Por, Eng])
  assert_eq(report.count(Spa, Some(Por)), 1)
  assert_eq(report.count(Por, Some(Spa)), 2)
  assert_eq(report.count(Eng, None), 1)
  assert_eq(report.count(Eng, Some(Spa)), 0)
}

///|
test "per-language precision, recall and F1" {
  let stats = sample_report().per_language()
  // Spanish: 4 of 5 found, 4 of 6 Spanish predictions right.
  assert_eq(stats[0].lang, Spa)
  assert_eq(stats[0].support, 5)
  assert_eq(stats[0].predicted, 6)
  assert_eq(stats[0].correct, 4)
  assert_eq(stats[0].precision, Some(4.0 / 6.0))
  assert_eq(stats[0].recall, Some(0.8))
  // Portuguese: 1 of 3 found, 1 of 2 predictions right.
  assert_eq(stats[1].precision, Some(0.5))
  assert_eq(stats[1].recall, Some(1.0 / 3.0))
  assert_eq(stats[1].f1, Some(0.4))
  // English: the unidentified sample lowers recall but not precision.
  assert_eq(stats[2].precision, Some(1.0))
  assert_eq(stats[2].recall, Some(0.5))
}

///|
test "a language that is never predicted has no precision and F1" {
  let report = @eval.evaluate(
    [{ lang: Fra, text: "f", }, { lang: Ita, text: "i", }],
    _ => Some(@mbglot.Ita),
  )
  let stats = report.per_language()
  assert_eq(stats[0].precision, None)
  assert_eq(stats[0].recall, Some(0.0))
  assert_eq(stats[0].f1, None)
  assert_eq(stats[1].precision, Some(0.5))
  assert_eq(report.macro_f1(), 2.0 / 3.0 / 2.0)
}

///|
test "wrong predictions only give an F1 of zero" {
  let report = @eval.evaluate(
    [{ lang: Fra, text: "f", }, { lang: Ita, text: "i", }],
    text => if text == "f" { Some(@mbglot.Ita) } else { Some(@mbglot.Fra) },
  )
  assert_eq(report.accuracy(), 0.0)
  assert_eq(report.per_language()[0].f1, Some(0.0))
  assert_eq(report.macro_f1(), 0.0)
}

///|
test "an empty report" {
  let report = @eval.evaluate([], _ => None)
  assert_eq(report.total(), 0)
  assert_eq(report.accuracy(), 0.0)
  assert_eq(report.macro_f1(), 0.0)
  assert_eq(report.per_language(), [])
  assert_eq(report.top_confusions(5), [])
}

///|
test "top confusions are ordered by count, then by language order" {
  let report = sample_report()
  assert_eq(report.top_confusions(10), [
    (Por, Some(Spa), 2),
    (Spa, Some(Por), 1),
    (Eng, None, 1),
  ])
  assert_eq(report.top_confusions(1), [(Por, Some(Spa), 2)])
  assert_eq(report.top_confusions(0), [])
}

///|
test "evaluating the same samples twice gives the same report" {
  let a = sample_report()
  let b = sample_report()
  assert_eq(a.to_markdown(), b.to_markdown())
}

///|
test "percent rounds to one decimal" {
  assert_eq(@eval.percent(0.0), "0.0%")
  assert_eq(@eval.percent(1.0), "100.0%")
  assert_eq(@eval.percent(2.0 / 3.0), "66.7%")
  assert_eq(@eval.percent(0.0004), "0.0%")
  assert_eq(@eval.percent(0.0005), "0.1%")
}

///|
test "markdown summary" {
  inspect(
    sample_report().to_markdown(),
    content=(
      #|Accuracy: 60.0% (6 of 10), unidentified: 1, macro F1: 59.8%
      #|
      #|| Language | Samples | Precision | Recall | F1 |
      #||---|---:|---:|---:|---:|
      #|| spa Spanish | 5 | 66.7% | 80.0% | 72.7% |
      #|| por Portuguese | 3 | 50.0% | 33.3% | 40.0% |
      #|| eng English | 2 | 100.0% | 50.0% | 66.7% |
      #|
      #|| Expected | Predicted | Count |
      #||---|---|---:|
      #|| por | spa | 2 |
      #|| spa | por | 1 |
      #|| eng | none | 1 |
      #|
    ),
  )
}

///|
test "confusion matrix" {
  inspect(
    sample_report().confusion_markdown([Spa, Por]),
    content=(
      #|| expected \ predicted | spa | por | other | none |
      #||---|---:|---:|---:|---:|
      #|| spa | 4 | 1 | 0 | 0 |
      #|| por | 2 | 1 | 0 | 0 |
      #|
    ),
  )
}
