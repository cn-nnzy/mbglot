///|
/// A stretch of text in one language, as returned by `segments`.
/// `start` and `end` are UTF-16 code unit offsets into the input and
/// `text` is that slice. `detection` is `None` only when the whole input
/// could not be identified.
pub(all) struct Segment {
  start : Int32
  end : Int32
  text : String
  detection : Detection?
} derive(Eq, Debug)

///|
/// Script class of a code point for splitting, or -1 for non-letters. Han,
/// Kana and Hangul share a class because Japanese mixes kanji and kana and
/// Korean may mix in hanja; `detect` tells them apart within a piece.
fn letter_class(cp : Int32) -> Int32 {
  for s in 0..<script_ranges.length() {
    if in_ranges(script_ranges[s], cp) {
      return if all_scripts[s] == Kana || all_scripts[s] == Hangul {
        0
      } else {
        s
      }
    }
  }
  -1
}

///|
/// 2 for marks that end a sentence on their own (newline, CJK full stops,
/// danda), 1 for marks that end one only when whitespace follows, else 0.
fn sentence_end(cp : Int32) -> Int32 {
  match cp {
    0x0A | 0x0D | 0x3002 | 0xFF01 | 0xFF1F | 0xFF0E | 0x0964 | 0x0965 => 2
    0x21 | 0x2E | 0x3F | 0x061F | 0x06D4 => 1
    _ => 0
  }
}

///|
/// Offsets where a new piece starts: before the first letter after a
/// sentence end (see `sentence_end`), and before a letter whose script
/// class differs from the previous letter's. Punctuation and spaces stay
/// with the preceding piece.
fn split_points(text : String) -> Array[Int32] {
  let points = [0]
  let mut last_class = -1
  let mut after_end = false
  let mut pending_end = false
  let mut i = 0
  while i < text.length() {
    let start = i
    let unit = text.unsafe_get(i).to_int()
    let mut cp = unit
    if unit >= 0xD800 && unit <= 0xDBFF && i + 1 < text.length() {
      let next = text.unsafe_get(i + 1).to_int()
      if next >= 0xDC00 && next <= 0xDFFF {
        cp = 0x10000 + ((unit - 0xD800) << 10) + (next - 0xDC00)
        i += 1
      }
    }
    i += 1
    let class = letter_class(cp)
    if class < 0 {
      match sentence_end(cp) {
        2 => after_end = true
        1 => pending_end = true
        _ =>
          if pending_end {
            after_end = after_end || is_js_space(cp)
            pending_end = false
          }
      }
      continue
    }
    pending_end = false
    if last_class >= 0 && (after_end || class != last_class) {
      points.push(start)
    }
    last_class = class
    after_end = false
  }
  points.push(text.length())
  points
}

///|
priv struct Piece {
  start : Int32
  end : Int32
  detection : Detection?
}

///|
fn slice(text : String, start : Int32, end : Int32) -> String {
  text.view(start_offset=start, end_offset=end).to_owned()
}

///|
/// Detections of the stretches of one text, each computed once: merging
/// pieces asks for the same stretch again.
priv struct Pieces {
  text : String
  detector : Detector
  cache : Map[(Int32, Int32), Detection?]
}

///|
fn Pieces::piece(self : Pieces, start : Int32, end : Int32) -> Piece {
  let detection = match self.cache.get((start, end)) {
    Some(d) => d
    None => {
      let d = self.detector.detect(slice(self.text, start, end))
      self.cache[(start, end)] = d
      d
    }
  }
  { start, end, detection, }
}

///|
fn piece_script(text : String, p : Piece) -> Script? {
  detect_script(slice(text, p.start, p.end))
}

///|
/// Splits `text` into consecutive segments in different languages. The
/// text is cut at sentence ends and where the writing system changes, each
/// piece is identified with `detect`, pieces that cannot be identified on
/// their own (too short, or without letters) are joined to a neighbour,
/// preferring one in the same script, and neighbours in the same language
/// are merged and identified again. The segments cover the whole input.
///
/// This is mbglot's own procedure built on franc's scores; franc has no
/// segmentation. Returns an empty array for empty text and one segment
/// with `detection` set to `None` when nothing in the text can be
/// identified.
pub fn segments(
  text : String,
  options~ : Options = default_options,
) -> Array[Segment] {
  detector_for(options).segments(text)
}

///|
/// Splits `text` into consecutive segments in different languages, as the
/// free function `segments` does.
pub fn Detector::segments(self : Detector, text : String) -> Array[Segment] {
  if text.length() == 0 {
    return []
  }
  if !self.options.strip_markup {
    return segments_of(text, self)
  }
  // Segment the text without markup, then map the boundaries back. A
  // removed stretch stays in the segment of the text before it.
  let stripped = strip_markup(text)
  let plain = { ..self, options: { ..self.options, strip_markup: false, }, }
  let raw = segments_of(stripped.text, plain)
  raw.mapi((i, s) => {
    let start = stripped.original_offset(s.start)
    let end = if i == raw.length() - 1 {
      text.length()
    } else {
      stripped.original_offset(s.end)
    }
    { start, end, text: slice(text, start, end), detection: s.detection, }
  })
}

///|
/// `segments` on text that is identified as it is.
fn segments_of(text : String, detector : Detector) -> Array[Segment] {
  let pieces_of = Pieces::{ text, detector, cache: Map([]), }
  let points = split_points(text)
  let pieces = []
  for i in 0..<(points.length() - 1) {
    if points[i] < points[i + 1] {
      pieces.push(pieces_of.piece(points[i], points[i + 1]))
    }
  }
  while pieces.length() > 1 {
    guard pieces.search_by(p => p.detection is None) is Some(i) else { break }
    let script = piece_script(text, pieces[i])
    let left = if i == 0 {
      false
    } else if i == pieces.length() - 1 {
      true
    } else {
      script is None ||
      piece_script(text, pieces[i - 1]) == script ||
      piece_script(text, pieces[i + 1]) != script
    }
    let (a, b) = if left { (i - 1, i) } else { (i, i + 1) }
    pieces[a] = pieces_of.piece(pieces[a].start, pieces[b].end)
    pieces.remove(b) |> ignore
  }
  let merged : Array[Piece] = []
  for p in pieces {
    match merged.last() {
      Some(prev) if prev.detection is Some(d) &&
        p.detection is Some(e) &&
        d.lang == e.lang =>
        merged[merged.length() - 1] = pieces_of.piece(prev.start, p.end)
      _ => merged.push(p)
    }
  }
  merged.map(p => {
    start: p.start,
    end: p.end,
    text: slice(text, p.start, p.end),
    detection: p.detection,
  })
}
