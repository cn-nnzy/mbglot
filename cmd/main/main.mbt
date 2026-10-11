///|
/// `x` with three decimals, computed with integers so that every backend
/// prints the same digits.
fn fixed3(x : Double) -> String {
  let scaled = (x * 1000.0).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs = scaled.abs()
  let frac = (abs % 1000).to_string()
  "\{sign}\{abs / 1000}.\{"0".repeat(3 - frac.length())}\{frac}"
}

///|
fn pad(s : String, width : Int) -> String {
  s + " ".repeat((width - s.length()).max(0))
}

///|
/// The lines printed for `text`.
fn report(text : String) -> Array[String] {
  guard @mbglot.detect(text) is Some(detection) else {
    return [
      "No language detected: the text is shorter than 10 characters or has no letters of a supported script.",
    ]
  }
  let lang = detection.lang
  let verdict = if detection.reliable { "reliable" } else { "not reliable" }
  let lines = [
    "language:   \{lang.name()} (\{lang.code()})",
    "script:     \{detection.script.name()}",
    "confidence: \{fixed3(detection.confidence)} (\{verdict})",
    "top 5:",
  ]
  for i, entry in @mbglot.rank(text) {
    if i == 5 {
      break
    }
    let (candidate, score) = entry
    lines.push(
      "  \{i + 1}. \{candidate.code()}  \{pad(candidate.name(), 24)} \{fixed3(score)}",
    )
  }
  lines
}

///|
/// `text` on one line, cut to `width` characters.
fn preview(text : String, width : Int) -> String {
  let chars = text
    .trim()
    .iter()
    .map(c => if c == '\n' || c == '\r' || c == '\t' { ' ' } else { c })
    .collect()
  if chars.length() <= width {
    String::from_array(chars)
  } else {
    String::from_array(chars[:width - 3]) + "..."
  }
}

///|
/// The lines printed for `text` with `--segments`.
fn segments_report(text : String) -> Array[String] {
  let parts = @mbglot.segments(text)
  if parts is [{ detection: None, .. }] || parts.is_empty() {
    return report(text)
  }
  parts.map(part => {
    let (code, name, verdict) = match part.detection {
      Some(d) =>
        (
          d.lang.code(),
          d.lang.name(),
          if d.reliable {
            "reliable"
          } else {
            "not reliable"
          },
        )
      None => ("---", "unidentified", "")
    }
    let range = pad(
      "[" + part.start.to_string() + ", " + part.end.to_string() + ")",
      12,
    )
    "\{range} \{code}  \{pad(name, 24)} \{pad(verdict, 12)} \{preview(part.text, 40)}"
  })
}

///|
let usage : String =
  #|usage: moon run cmd/main -- "text to identify"
  #|       moon run cmd/main -- --segments "text mixing languages"
  #|
  #|Prints the most likely language, its script, the confidence (margin to
  #|the runner-up) and the five best candidates with franc-min's scores.
  #|With --segments, prints one line per language segment: its UTF-16
  #|offsets, language, reliability and the start of its text.

///|
fn main {
  let args = @env.args()
  let lines = match args[1:] {
    [] | ["--help" | "-h"] | ["--segments"] => [usage]
    ["--segments", .. rest] => segments_report(rest.join(" "))
    rest => report(rest.join(" "))
  }
  for line in lines {
    println(line)
  }
}
