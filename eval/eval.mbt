///|
/// A text with its known language.
pub(all) struct Sample {
  lang : @mbglot.Lang
  text : String
} derive(Eq, Debug)

///|
/// Accuracy figures for one language. `precision` is `None` when no
/// sample was predicted as this language, `recall` when it has no samples.
pub(all) struct LangStats {
  lang : @mbglot.Lang
  /// Samples whose expected language is `lang`.
  support : Int32
  /// Samples predicted as `lang`, correct or not.
  predicted : Int32
  /// Samples of `lang` predicted as `lang`.
  correct : Int32
  precision : Double?
  recall : Double?
  f1 : Double?
} derive(Eq, Debug)

///|
/// The outcome of `evaluate`: how every sample was classified.
pub struct Report {
  priv total : Int32
  priv correct : Int32
  priv unidentified : Int32
  /// (expected, predicted) to count; `None` when nothing was detected.
  priv confusion : Map[(@mbglot.Lang, @mbglot.Lang?), Int32]
  /// Expected languages in order of first appearance.
  priv langs : Array[@mbglot.Lang]
}

///|
/// Runs `predict` on every sample and tallies the results. `predict`
/// returns `None` when it declines to identify a text; such a sample counts
/// as wrong for accuracy and recall, but as a prediction of no language for
/// precision.
pub fn evaluate(
  samples : Array[Sample],
  predict : (String) -> @mbglot.Lang?,
) -> Report {
  let confusion : Map[(@mbglot.Lang, @mbglot.Lang?), Int32] = Map([])
  let langs = []
  let seen : Set[@mbglot.Lang] = Set([])
  let mut correct = 0
  let mut unidentified = 0
  for sample in samples {
    if !seen.contains(sample.lang) {
      seen.add(sample.lang)
      langs.push(sample.lang)
    }
    let predicted = predict(sample.text)
    match predicted {
      Some(lang) if lang == sample.lang => correct += 1
      None => unidentified += 1
      _ => ()
    }
    let key = (sample.lang, predicted)
    confusion[key] = confusion.get(key).unwrap_or(0) + 1
  }
  { total: samples.length(), correct, unidentified, confusion, langs, }
}

///|
/// Number of samples.
pub fn Report::total(self : Report) -> Int32 {
  self.total
}

///|
/// Number of samples predicted as their expected language.
pub fn Report::correct(self : Report) -> Int32 {
  self.correct
}

///|
/// Number of samples for which no language was predicted.
pub fn Report::unidentified(self : Report) -> Int32 {
  self.unidentified
}

///|
/// Share of samples predicted correctly, 0.0 for an empty report.
pub fn Report::accuracy(self : Report) -> Double {
  if self.total == 0 {
    0.0
  } else {
    self.correct.to_double() / self.total.to_double()
  }
}

///|
/// How many samples of language `expected` were predicted as `predicted`
/// (`None`: not identified).
pub fn Report::count(
  self : Report,
  expected : @mbglot.Lang,
  predicted : @mbglot.Lang?,
) -> Int32 {
  self.confusion.get((expected, predicted)).unwrap_or(0)
}

///|
/// The expected languages, in order of first appearance in the samples.
pub fn Report::languages(self : Report) -> Array[@mbglot.Lang] {
  self.langs.copy()
}

///|
fn ratio(num : Int32, den : Int32) -> Double? {
  if den == 0 {
    None
  } else {
    Some(num.to_double() / den.to_double())
  }
}

///|
/// Precision, recall and F1 for every expected language, in order of
/// first appearance.
pub fn Report::per_language(self : Report) -> Array[LangStats] {
  let support : Map[@mbglot.Lang, Int32] = Map([])
  let predicted : Map[@mbglot.Lang, Int32] = Map([])
  for key, n in self.confusion {
    let (expected, guess) = key
    support[expected] = support.get(expected).unwrap_or(0) + n
    if guess is Some(lang) {
      predicted[lang] = predicted.get(lang).unwrap_or(0) + n
    }
  }
  self.langs.map(lang => {
    let support = support.get(lang).unwrap_or(0)
    let predicted = predicted.get(lang).unwrap_or(0)
    let correct = self.count(lang, Some(lang))
    let precision = ratio(correct, predicted)
    let recall = ratio(correct, support)
    let f1 = match (precision, recall) {
      (Some(p), Some(r)) if p + r > 0.0 => Some(2.0 * p * r / (p + r))
      (Some(_), Some(_)) => Some(0.0)
      _ => None
    }
    { lang, support, predicted, correct, precision, recall, f1, }
  })
}

///|
/// Mean F1 over the expected languages, counting a language that was
/// never predicted as 0.
pub fn Report::macro_f1(self : Report) -> Double {
  let stats = self.per_language()
  if stats.is_empty() {
    return 0.0
  }
  let mut sum = 0.0
  for s in stats {
    sum += s.f1.unwrap_or(0.0)
  }
  sum / stats.length().to_double()
}

///|
/// The `n` most frequent mistakes as (expected, predicted, count), most
/// frequent first; ties are ordered by expected language, then by
/// prediction, in `Lang::all()` order with `None` last.
pub fn Report::top_confusions(
  self : Report,
  n : Int32,
) -> Array[(@mbglot.Lang, @mbglot.Lang?, Int32)] {
  let order : Map[@mbglot.Lang, Int32] = Map([])
  for i, lang in @mbglot.Lang::all() {
    order[lang] = i
  }
  let rank = (lang : @mbglot.Lang?) => {
    match lang {
      Some(l) => order.get(l).unwrap_or(0)
      None => order.length()
    }
  }
  let mistakes = []
  for key, count in self.confusion {
    let (expected, predicted) = key
    if predicted != Some(expected) {
      mistakes.push((expected, predicted, count))
    }
  }
  mistakes.sort_by((a, b) => {
    if a.2 != b.2 {
      return b.2.compare(a.2)
    }
    let by_expected = rank(Some(a.0)).compare(rank(Some(b.0)))
    if by_expected != 0 {
      by_expected
    } else {
      rank(a.1).compare(rank(b.1))
    }
  })
  if mistakes.length() > n {
    mistakes.truncate(n)
  }
  mistakes
}
