///|
/// `detection` of `text` as JSON. Chinese also gets the variant of its
/// characters ("simplified", "traditional" or null).
fn detection_json(detection : @mbglot.Detection, text : String) -> Json {
  let variant : Json = match detection.lang {
    Cmn =>
      match @mbglot.chinese_variant(text) {
        Some(Simplified) => "simplified".to_json()
        Some(Traditional) => "traditional".to_json()
        None => Json::null()
      }
    _ => Json::null()
  }
  {
    "variant": variant,
    "lang": detection.lang.code().to_json(),
    "name": detection.lang.name().to_json(),
    "script": detection.script.name().to_json(),
    "confidence": detection.confidence.to_json(),
    "reliable": detection.reliable.to_json(),
  }
}

///|
/// Everything the demo page shows for `text`, as a JSON string: the
/// detection (or null), the five best candidates and the language
/// segments with UTF-16 offsets, which index JavaScript strings directly.
pub fn analyze(text : String) -> String {
  let detection : Json = match @mbglot.detect(text) {
    Some(d) => detection_json(d, text)
    None => Json::null()
  }
  let ranked = @mbglot.rank(text)
  let top : Array[Json] = []
  for i, entry in ranked {
    if i == 5 {
      break
    }
    let (lang, score) = entry
    top.push({
      "lang": lang.code().to_json(),
      "name": lang.name().to_json(),
      "score": score.to_json(),
    })
  }
  let segments : Array[Json] = @mbglot.segments(text).map(segment => {
    "start": segment.start.to_json(),
    "end": segment.end.to_json(),
    "detection": match segment.detection {
      Some(d) => detection_json(d, segment.text)
      None => Json::null()
    },
  })
  let result : Json = {
    "detection": detection,
    "top": Json::array(top),
    "segments": Json::array(segments),
  }
  result.stringify()
}
