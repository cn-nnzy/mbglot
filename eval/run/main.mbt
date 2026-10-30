///|
/// mbglot's prediction for `text` under `options`: the detected language,
/// if any.
fn any_detection(options : @mbglot.Options) -> (String) -> @mbglot.Lang? {
  text => {
    match @mbglot.detect(text, options~) {
      Some(d) => Some(d.lang)
      None => None
    }
  }
}

///|
/// mbglot's prediction for `text` when it is reliable, as a router that
/// sends uncertain messages to manual triage would use it.
fn reliable_detection(options : @mbglot.Options) -> (String) -> @mbglot.Lang? {
  text => {
    match @mbglot.detect(text, options~) {
      Some(d) if d.reliable => Some(d.lang)
      _ => None
    }
  }
}

///|
/// Share of answered samples that were right.
fn answered_precision(report : @eval.Report) -> Double {
  let answered = report.total() - report.unidentified()
  if answered == 0 {
    0.0
  } else {
    report.correct().to_double() / answered.to_double()
  }
}

///|
fn mode_name(mode : @mbglot.Mode) -> String {
  match mode {
    Franc => "franc"
    Enhanced => "enhanced"
  }
}

///|
/// Languages that are hard or impossible to tell apart in short written
/// text: dialect continua and standards of one language.
let groups : Array[Array[@mbglot.Lang]] = [
  [Bos, Hrv, Srp],
  [Ind, Zlm],
  [Hin, Bho, Mai, Mag],
  [Run, Kin],
]

///|
/// `lang`, or the first language of its group in `groups`.
fn group_of(lang : @mbglot.Lang) -> @mbglot.Lang {
  for group in groups {
    if group.contains(lang) {
      return group[0]
    }
  }
  lang
}

///|
/// Share of samples whose prediction is in the expected language's group.
fn group_accuracy(
  samples : Array[@eval.Sample],
  predict : (String) -> @mbglot.Lang?,
) -> Double {
  let grouped = samples.map(s => @eval.Sample::{
    lang: group_of(s.lang),
    text: s.text,
  })
  @eval.evaluate(grouped, text => predict(text).map(group_of)).accuracy()
}

///|
/// One row per length and mode for the samples of `split`.
fn summary_table(buf : StringBuilder, split : @tatoeba.Split) -> Unit raise {
  buf.write_string(
    "| Length | Mode | Samples | Accuracy | Group accuracy | Macro F1 | Reliable precision | Coverage |\n",
  )
  buf.write_string("|---|---|---:|---:|---:|---:|---:|---:|\n")
  let lengths : Array[@tatoeba.Length?] = [
    Some(Short),
    Some(Medium),
    Some(Long),
    None,
  ]
  for length in lengths {
    let name = match length {
      Some(l) => l.name()
      None => "all"
    }
    mode_rows(buf, name, @tatoeba.samples(length?, split~))
  }
}

///|
/// One row per mode for `samples`, labelled `name`.
fn mode_rows(
  buf : StringBuilder,
  name : String,
  samples : Array[@eval.Sample],
) -> Unit raise {
  let modes : Array[@mbglot.Mode] = [Franc, Enhanced]
  for mode in modes {
    let options = @mbglot.Options::new(mode~)
    let all = @eval.evaluate(samples, any_detection(options))
    let reliable = @eval.evaluate(samples, reliable_detection(options))
    let coverage = 1.0 -
      reliable.unidentified().to_double() / reliable.total().to_double()
    buf.write_string(
      "| \{name} | \{mode_name(mode)} | \{all.total()} | " +
      "\{@eval.percent(all.accuracy())} | " +
      "\{@eval.percent(group_accuracy(samples, any_detection(options)))} | " +
      "\{@eval.percent(all.macro_f1())} | " +
      "\{@eval.percent(answered_precision(reliable))} | " +
      "\{@eval.percent(coverage)} |\n",
    )
  }
}

///|
/// Both modes on the FLORES-200 sentences, and enhanced mode's most
/// frequent mistakes there.
fn flores_section(buf : StringBuilder) -> Unit raise {
  let samples = @flores.samples()
  buf.write_string(
    "\n## FLORES-200\n\n" +
    "A second, out-of-domain corpus: the same 40 FLORES-200 devtest " +
    "sentences (news and travel articles translated from English, CC BY-SA " +
    "4.0) in \{@flores.languages().length()} of the languages (see " +
    "eval/flores). Nothing was tuned on it.\n\n",
  )
  buf.write_string(
    "| Corpus | Mode | Samples | Accuracy | Group accuracy | Macro F1 | Reliable precision | Coverage |\n",
  )
  buf.write_string("|---|---|---:|---:|---:|---:|---:|---:|\n")
  mode_rows(buf, "flores", samples)
  let report = @eval.evaluate(samples, any_detection(@mbglot.Options::new()))
  buf.write_string("\n| Expected | Predicted (enhanced) | Count |\n")
  buf.write_string("|---|---|---:|\n")
  for m in report.top_confusions(10) {
    let predicted = match m.1 {
      Some(lang) => lang.code()
      None => "none"
    }
    buf.write_string("| \{m.0.code()} | \{predicted} | \{m.2} |\n")
  }
}

///|
/// The languages with franc-min profiles whose benchmark samples are in
/// Latin script.
fn latin_languages() -> Array[@mbglot.Lang] {
  @tatoeba.languages().filter(lang => {
    let samples = @tatoeba.samples(split=Dev).filter(s => s.lang == lang)
    @mbglot.Profile::of_lang(lang) is Some(_) &&
    samples.length() > 0 &&
    @mbglot.detect_script(samples[0].text) == Some(Latin)
  })
}

///|
/// Accuracy on the test half of a classifier with franc-min's profiles
/// and of one with profiles trained on the dev half, for the Latin-script
/// languages.
fn custom_profiles(buf : StringBuilder) -> Unit raise {
  let langs = latin_languages()
  let samples = @tatoeba.samples(split=Test).filter(s => langs.contains(s.lang))
  let franc = langs.map(lang => @mbglot.Profile::of_lang(lang).unwrap())
  let trained = langs.map(lang => {
    let text = @tatoeba.samples(split=Dev)
      .filter(s => s.lang == lang)
      .map(s => s.text)
      .join("\n")
    @mbglot.Profile::train(lang.code(), text)
  })
  buf.write_string(
    "| Profiles | Languages | Samples | Accuracy | Macro F1 |\n|---|---:|---:|---:|---:|\n",
  )
  for entry in [("franc-min", franc), ("trained on the dev half", trained)] {
    let classifier = @mbglot.Classifier::new(entry.1)
    let report = @eval.evaluate(samples, text => {
      classifier.classify(text).bind(@mbglot.Lang::from_code)
    })
    buf.write_string(
      "| \{entry.0} | \{langs.length()} | \{report.total()} | " +
      "\{@eval.percent(report.accuracy())} | \{@eval.percent(report.macro_f1())} |\n",
    )
  }
}

///|
/// The benchmark report in Markdown. `eval/results.md` holds its output;
/// CI checks that it is up to date.
fn benchmark() -> String raise {
  let buf = StringBuilder()
  let langs = @tatoeba.languages()
  buf.write_string(
    "# Benchmark\n\nmbglot on Tatoeba sentences in \{langs.length()} languages " +
    "(see eval/tatoeba). Generated by `moon run eval/run`; do not edit.\n\n" +
    "`franc` is `Mode::Franc` (franc-min's ranking alone), `enhanced` is " +
    "`Mode::Enhanced` (the default). Accuracy counts every detection. " +
    "Group accuracy also counts a language of the expected language's group " +
    "as right (bos/hrv/srp, ind/zlm, hin/bho/mai/mag, run/kin). " +
    "Reliable precision is the share of reliable detections that are right, " +
    "and coverage the share of samples with a reliable detection.\n\n" +
    "The samples of each language and length alternate between a dev half " +
    "and a test half. Weights and thresholds are chosen on the dev half; " +
    "the test half is held out, and its figures come first.\n\n" +
    "## Test half\n\n",
  )
  summary_table(buf, Test)
  buf.write_string("\n## Every length, enhanced mode, test half\n\n")
  buf.write_string(
    @eval.evaluate(
      @tatoeba.samples(split=Test),
      any_detection(@mbglot.Options::new()),
    ).to_markdown(confusions=20),
  )
  flores_section(buf)
  buf.write_string("\n## Dev half\n\n")
  summary_table(buf, Dev)
  buf.write_string(
    "\n## Custom profiles\n\n" +
    "A `Classifier` with franc-min's profiles of the Latin-script languages " +
    "against one with 300-trigram profiles trained on the dev half " +
    "(`Profile::train`), on the test half. Trigram distance only, without " +
    "the passes of `Mode::Enhanced`.\n\n",
  )
  custom_profiles(buf)
  buf.to_string()
}

///|
fn main {
  println(benchmark().trim_end()) catch {
    e => println("benchmark failed: \{e}")
  }
}
