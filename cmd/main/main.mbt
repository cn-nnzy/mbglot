// The mbglot command: identifies the language of a text, of its segments,
// or of every line of a file.

///|
/// What the command line asks for.
priv struct Settings {
  /// The text to identify: the positional arguments joined with spaces.
  text : String
  /// A file whose lines are identified one by one, instead of `text`.
  file : String?
  segments : Bool
  json : Bool
  /// How many candidates to list.
  top : Int32
  options : @mbglot.Options
}

///|
/// A command line that cannot be run, with the message to show.
priv suberror Usage {
  Usage(String)
}

///|
impl Show for Usage with fn output(self, logger) {
  let Usage(message) = self
  logger.write_string(message)
}

///|
fn command() -> @argparse.Command {
  @argparse.Command(
    "mbglot",
    about="Identifies the language of a text: the most likely language, its script, the confidence (franc's score margin to the runner-up, plus the letters and common words that favour the language in enhanced mode), whether it is reliable, and the best candidates. With --file, identifies every line of a file and prints one result per line.",
    flags=[
      @argparse.FlagArg(
        "segments",
        about="split text that mixes languages into segments and identify each",
      ),
      @argparse.FlagArg(
        "json",
        about="print JSON: one object, or with --file one object per line",
      ),
    ],
    options=[
      @argparse.OptionArg(
        "file",
        short='f',
        about="identify each line of this file; empty lines give an empty result, so output line N belongs to input line N",
      ),
      @argparse.OptionArg(
        "top",
        about="how many candidates to list (default 5; with --file, default 0)",
      ),
      @argparse.OptionArg(
        "allow",
        action=Append,
        about="only consider these languages: ISO 639-3 codes separated by commas, such as eng,fra,deu",
      ),
      @argparse.OptionArg(
        "deny",
        action=Append,
        about="never return these languages: ISO 639-3 codes separated by commas",
      ),
      @argparse.OptionArg(
        "mode",
        about="enhanced (default): markup removed and related languages settled by letters and words; franc: franc-min's ranking alone",
      ),
      @argparse.OptionArg(
        "min-length",
        about="texts shorter than this many UTF-16 code units are not identified (default 10)",
      ),
    ],
    positionals=[
      @argparse.PositionArg(
        "text",
        about="the text to identify",
        num_args=@argparse.ValueRange(lower=0),
      ),
    ],
  )
}

///|
/// The last value given for option `name`, if any.
fn last_value(matches : @argparse.Matches, name : String) -> String? {
  match matches.values.get(name) {
    Some([.., last]) => Some(last)
    _ => None
  }
}

///|
/// The languages in the comma-separated lists given for option `name`.
fn languages(
  matches : @argparse.Matches,
  name : String,
) -> Array[@mbglot.Lang]? raise Usage {
  guard matches.values.get(name) is Some(lists) else { return None }
  let langs = []
  for list in lists {
    for code in list.split(",") {
      let code = code.trim().to_owned()
      guard @mbglot.Lang::from_code(code) is Some(lang) else {
        raise Usage(
          "error: --\{name}: unknown language code \"\{code}\"; use ISO 639-3 codes such as eng or cmn",
        )
      }
      if !langs.contains(lang) {
        langs.push(lang)
      }
    }
  }
  Some(langs)
}

///|
/// The value of option `name` as a non-negative integer.
fn count(
  matches : @argparse.Matches,
  name : String,
  default : Int32,
) -> Int32 raise Usage {
  guard last_value(matches, name) is Some(value) else { return default }
  let n = @string.parse_int(value) catch {
    _ => raise Usage("error: --\{name} takes a number; got \"\{value}\"")
  }
  if n < 0 {
    raise Usage("error: --\{name} must not be negative; got \{n}")
  }
  n
}

///|
/// Without `argv`, the command line of this process; `--help` then prints
/// the help and exits.
fn parse_args(argv? : ArrayView[String]) -> Settings raise {
  let matches = command().parse(argv?)
  let text = matches.values.get_or_default("text", []).join(" ")
  let file = last_value(matches, "file")
  match (file, text) {
    (Some(_), "") => ()
    (Some(_), _) => raise Usage("error: give either a text or --file, not both")
    (None, "") =>
      raise Usage(
        "error: nothing to identify; give a text or --file (see --help)",
      )
    (None, _) => ()
  }
  let mode : @mbglot.Mode = match last_value(matches, "mode") {
    None | Some("enhanced") => Enhanced
    Some("franc") => Franc
    Some(other) =>
      raise Usage("error: --mode takes enhanced or franc; got \"\{other}\"")
  }
  let allow = languages(matches, "allow")
  let deny = languages(matches, "deny").unwrap_or([])
  let min_length = count(matches, "min-length", 10)
  let options = @mbglot.Options::new(allow?, deny~, min_length~, mode~) catch {
    EmptyAllow => raise Usage("error: --allow lists no language")
    AllowDenyOverlap(lang) =>
      raise Usage("error: \{lang.code()} is both allowed and denied")
    DenyAll => raise Usage("error: --deny lists every language")
    NegativeMinLength(_) => raise Usage("error: --min-length is negative")
  }
  {
    text,
    file,
    segments: matches.flags.get_or_default("segments", false),
    json: matches.flags.get_or_default("json", false),
    top: count(matches, "top", if file is Some(_) { 0 } else { 5 }),
    options,
  }
}

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
/// `x` rounded to three decimals, for JSON.
fn round3(x : Double) -> Json {
  Json((x * 1000.0).round() / 1000.0)
}

///|
fn pad(s : String, width : Int32) -> String {
  s + " ".repeat((width - s.length()).max(0))
}

///|
fn verdict(detection : @mbglot.Detection) -> String {
  if detection.reliable {
    "reliable"
  } else {
    "not reliable"
  }
}

///|
/// The lines printed for `text`.
fn report(
  text : String,
  detector : @mbglot.Detector,
  top : Int32,
) -> Array[String] {
  guard detector.detect(text) is Some(detection) else {
    return [
      "No language detected: the text is shorter than \{detector.options().min_length()} characters or has no letters of a supported script.",
    ]
  }
  let lang = detection.lang
  let lines = [
    "language:   \{lang.name()} (\{lang.code()})",
    "script:     \{detection.script.name()}",
    "confidence: \{fixed3(detection.confidence)} (\{verdict(detection)})",
  ]
  if detection.runner_up is Some(other) {
    lines.push(
      "runner-up:  \{other.name()} (\{other.code()}), margin \{fixed3(detection.margin)}",
    )
  }
  if top > 0 {
    lines.push("top \{top}:")
    for i, entry in detector.rank(text) {
      if i == top {
        break
      }
      let (candidate, score) = entry
      lines.push(
        "  \{i + 1}. \{candidate.code()}  \{pad(candidate.name(), 24)} \{fixed3(score)}",
      )
    }
  }
  lines
}

///|
/// `text` on one line, cut to `width` characters.
fn preview(text : String, width : Int32) -> String {
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
fn segments_report(
  text : String,
  detector : @mbglot.Detector,
  top : Int32,
) -> Array[String] {
  let parts = detector.segments(text)
  if parts is [{ detection: None, .. }] || parts.is_empty() {
    return report(text, detector, top)
  }
  parts.map(part => {
    let (code, name, verdict) = match part.detection {
      Some(d) => (d.lang.code(), d.lang.name(), verdict(d))
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
fn detection_json(detection : @mbglot.Detection?) -> Json {
  guard detection is Some(d) else { return Json::null() }
  {
    "lang": Json(d.lang.code()),
    "name": Json(d.lang.name()),
    "script": Json(d.script.name()),
    "confidence": round3(d.confidence),
    "margin": round3(d.margin),
    "reliable": Json(d.reliable),
    "runner_up": match d.runner_up {
      Some(lang) => Json(lang.code())
      None => Json::null()
    },
  }
}

///|
/// The result for `text` as JSON: the detection (or null), the `top` best
/// candidates and, with `segments`, the segments with UTF-16 offsets.
fn json_report(
  text : String,
  detector : @mbglot.Detector,
  top : Int32,
  segments : Bool,
) -> Json {
  let candidates : Array[Json] = []
  if top > 0 {
    for i, entry in detector.rank(text) {
      if i == top {
        break
      }
      candidates.push({ "lang": Json(entry.0.code()), "score": round3(entry.1) })
    }
  }
  let result : Map[String, Json] = {
    "detection": detection_json(detector.detect(text)),
    "top": Json::array(candidates),
  }
  if segments {
    result["segments"] = Json::array(
      detector
      .segments(text)
      .map(part => {
        "start": Json(part.start),
        "end": Json(part.end),
        "detection": detection_json(part.detection),
      }),
    )
  }
  Json::object(result)
}

///|
/// One tab-separated line for line `number` of a file: the number, the
/// language code, the confidence and whether it is reliable, or dashes
/// when nothing was detected.
fn batch_line(number : Int32, detection : @mbglot.Detection?) -> String {
  match detection {
    Some(d) =>
      "\{number}\t\{d.lang.code()}\t\{fixed3(d.confidence)}\t\{verdict(d)}"
    None => "\{number}\t-\t-\t-"
  }
}

///|
/// The lines printed for the lines of a file.
fn batch_report(contents : String, settings : Settings) -> Array[String] {
  let detector = @mbglot.Detector::new(options=settings.options)
  let lines = contents
    .split("\n")
    .map(line => line.trim_end(chars="\r").to_owned())
    .collect()
  if lines.last() == Some("") {
    lines.pop() |> ignore
  }
  let out = []
  for i, line in lines {
    let number = i + 1
    if settings.json {
      let result = json_report(line, detector, settings.top, settings.segments)
      if result is Object(fields) {
        fields["line"] = Json(number)
      }
      out.push(result.stringify())
    } else if settings.segments {
      for part in segments_report(line, detector, settings.top) {
        out.push("\{number}\t\{part}")
      }
    } else {
      out.push(batch_line(number, detector.detect(line)))
      if settings.top > 0 {
        for k, entry in detector.rank(line) {
          if k == settings.top {
            break
          }
          out.push("\{number}\t  \{entry.0.code()}\t\{fixed3(entry.1)}")
        }
      }
    }
  }
  out
}

///|
/// The lines printed for the text of the command line.
fn text_report(settings : Settings) -> Array[String] {
  let detector = @mbglot.Detector::new(options=settings.options)
  if settings.json {
    [
      json_report(settings.text, detector, settings.top, settings.segments).stringify(),
    ]
  } else if settings.segments {
    segments_report(settings.text, detector, settings.top)
  } else {
    report(settings.text, detector, settings.top)
  }
}

///|
fn main {
  let settings = parse_args() catch {
    error => {
      eprintln(error)
      @sys.exit(2)
      return
    }
  }
  let lines = match settings.file {
    None => text_report(settings)
    Some(path) =>
      try @fs.read_file_to_string(path) catch {
        @fs.IOError(message) => {
          eprintln("\{path}: error: \{message}")
          @sys.exit(1)
          return
        }
      } noraise {
        contents => batch_report(contents, settings)
      }
  }
  for line in lines {
    println(line)
  }
}
