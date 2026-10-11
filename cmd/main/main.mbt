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
let usage : String =
  #|usage: moon run cmd/main -- "text to identify"
  #|
  #|Prints the most likely language, its script, the confidence (margin to
  #|the runner-up) and the five best candidates with franc-min's scores.

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println(usage)
    return
  }
  for line in report(args[1:].join(" ")) {
    println(line)
  }
}
