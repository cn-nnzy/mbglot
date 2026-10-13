///|
/// `x` as a percentage with one decimal, computed with integers so that
/// every backend prints the same digits.
pub fn percent(x : Double) -> String {
  let tenths = (x * 1000.0).round().to_int()
  "\{tenths / 10}.\{tenths % 10}%"
}

///|
fn percent_or_dash(x : Double?) -> String {
  match x {
    Some(v) => percent(v)
    None => "-"
  }
}

///|
fn lang_label(lang : @mbglot.Lang?) -> String {
  match lang {
    Some(l) => l.code()
    None => "none"
  }
}

///|
/// A Markdown summary of the report: overall accuracy, a table with
/// precision, recall and F1 per language (in order of first appearance),
/// and the `confusions` most frequent mistakes.
pub fn Report::to_markdown(self : Report, confusions? : Int = 10) -> String {
  let buf = StringBuilder()
  buf.write_string(
    "Accuracy: \{percent(self.accuracy())} (\{self.correct} of \{self.total}), " +
    "unidentified: \{self.unidentified}, macro F1: \{percent(self.macro_f1())}\n\n",
  )
  buf.write_string("| Language | Samples | Precision | Recall | F1 |\n")
  buf.write_string("|---|---:|---:|---:|---:|\n")
  for s in self.per_language() {
    buf.write_string(
      "| \{s.lang.code()} \{s.lang.name()} | \{s.support} | " +
      "\{percent_or_dash(s.precision)} | \{percent_or_dash(s.recall)} | " +
      "\{percent_or_dash(s.f1)} |\n",
    )
  }
  let mistakes = self.top_confusions(confusions)
  if !mistakes.is_empty() {
    buf.write_string("\n| Expected | Predicted | Count |\n")
    buf.write_string("|---|---|---:|\n")
    for m in mistakes {
      let (expected, predicted, count) = m
      buf.write_string(
        "| \{expected.code()} | \{lang_label(predicted)} | \{count} |\n",
      )
    }
  }
  buf.to_string()
}

///|
/// The confusion matrix over `langs` as a Markdown table: one row per
/// expected language, one column per predicted language in `langs`, then
/// a column for other languages and one for no prediction.
pub fn Report::confusion_markdown(
  self : Report,
  langs : Array[@mbglot.Lang],
) -> String {
  let buf = StringBuilder()
  buf.write_string("| expected \\ predicted |")
  for lang in langs {
    buf.write_string(" \{lang.code()} |")
  }
  buf.write_string(" other | none |\n|---|")
  for _ in langs {
    buf.write_string("---:|")
  }
  buf.write_string("---:|---:|\n")
  for expected in langs {
    buf.write_string("| \{expected.code()} |")
    let mut listed = 0
    for predicted in langs {
      let n = self.count(expected, Some(predicted))
      listed += n
      buf.write_string(" \{n} |")
    }
    let none = self.count(expected, None)
    let mut row = 0
    for key, n in self.confusion {
      if key.0 == expected {
        row += n
      }
    }
    buf.write_string(" \{row - listed - none} | \{none} |\n")
  }
  buf.to_string()
}
