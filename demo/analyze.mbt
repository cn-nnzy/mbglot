///|
/// `detection` of `text` as JSON. Chinese also gets the variant of its
/// characters ("simplified", "traditional" or null).
fn detection_json(detection : @mbglot.Detection, text : String) -> Json {
  let variant : Json = match detection.lang {
    Cmn =>
      match @mbglot.chinese_variant(text) {
        Some(Simplified) => Json("simplified")
        Some(Traditional) => Json("traditional")
        None => Json::null()
      }
    _ => Json::null()
  }
  {
    "variant": variant,
    "lang": Json(detection.lang.code()),
    "bcp47": Json(detection.lang.bcp47()),
    "name": Json(detection.lang.name()),
    "native": Json(detection.lang.native_name()),
    "script": Json(detection.script.name()),
    "confidence": Json(detection.confidence),
    "reliable": Json(detection.reliable),
  }
}

///|
/// A step of the decision (see `@mbglot.Step`) as JSON: its kind, the
/// language it chose, the letters or words that decided it and, for a
/// near tie, the language it beat.
fn step_json(step : @mbglot.Step) -> Json {
  let (kind, lang, clues, over) = match step {
    Trigrams(lang) => ("trigrams", lang, [], None)
    ScriptShare(lang) => ("script_share", lang, [], None)
    CommonWords(lang, words) => ("common_words", lang, words, None)
    RelatedLanguages(lang, words) => ("related_languages", lang, words, None)
    NearTie(lang, other) => ("near_tie", lang, [], Some(other))
  }
  {
    "step": Json(kind),
    "name": Json(lang.name()),
    "clues": Json::array(clues.map(c => Json(c))),
    "over": match over {
      Some(other) => Json(other.name())
      None => Json::null()
    },
  }
}

///|
/// Everything the demo page shows for `text` in the default mode; see
/// `analyze_in`.
pub fn analyze(text : String) -> String {
  analyze_in(text, "enhanced")
}

///|
/// Everything the demo page shows for `text` in `mode` ("enhanced" or
/// "franc"), as a JSON string: the detection (or null), the five best
/// candidates, the language segments with UTF-16 offsets, which index
/// JavaScript strings directly, the steps that decided the language, and
/// what franc-min's ranking alone would say (`franc`, the language or
/// null), so the page can show where the enhanced passes changed it.
pub fn analyze_in(text : String, mode : String) -> String {
  let franc_options = @mbglot.Options::new(mode=Franc) catch {
    _ => abort("unreachable")
  }
  let options = if mode == "franc" {
    franc_options
  } else {
    @mbglot.Options::new() catch {
      _ => abort("unreachable")
    }
  }
  let detector = @mbglot.Detector::new(options~)
  let detection : Json = match detector.detect(text) {
    Some(d) => detection_json(d, text)
    None => Json::null()
  }
  let top : Array[Json] = []
  for i, entry in detector.rank(text) {
    if i == 5 {
      break
    }
    let (lang, score) = entry
    top.push({
      "lang": Json(lang.code()),
      "name": Json(lang.name()),
      "score": Json(score),
    })
  }
  let segments : Array[Json] = detector
    .segments(text)
    .map(segment => {
      "start": Json(segment.start),
      "end": Json(segment.end),
      "detection": match segment.detection {
        Some(d) => detection_json(d, segment.text)
        None => Json::null()
      },
    })
  let franc : Json = match @mbglot.detect(text, options=franc_options) {
    Some(d) => { "lang": Json(d.lang.code()), "name": Json(d.lang.name()) }
    None => Json::null()
  }
  let result : Json = {
    "detection": detection,
    "top": Json::array(top),
    "segments": Json::array(segments),
    "why": Json::array(detector.explain(text).steps.map(step_json)),
    "franc": franc,
  }
  result.stringify()
}
