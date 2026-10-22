///|
/// Kind of text that `strip_markup` removes.
pub(all) enum Markup {
  /// `http://`, `https://`, `ftp://` or `www.` address.
  Url
  /// `name@example.com`.
  Email
  /// `@name` at the start of a word.
  Mention
  /// `#tag` at the start of a word, with at least one letter.
  Hashtag
  /// An HTML or XML tag, comment or doctype, `<b>` or `<!-- x -->`.
  HtmlTag
  /// An HTML character reference, `&amp;` or `&#233;`.
  HtmlEntity
  /// A Markdown code span or fenced code block, or the content of an HTML
  /// `code`, `pre`, `script` or `style` element.
  Code
} derive(Eq, Debug)

///|
/// A stretch of the input that `strip_markup` removed.
pub(all) struct Removed {
  start : Int32
  end : Int32
  kind : Markup
} derive(Eq, Debug)

///|
/// Text with markup removed, and a map from its offsets back to the input.
/// Each removed stretch is replaced by one space so that the words around
/// it stay apart.
pub struct Stripped {
  text : String
  removed : Array[Removed]
  /// `origin[i]` is the input offset of `text[i]`; one more entry maps the
  /// end of `text` to the end of the input.
  priv origin : Array[Int32]
}

///|
/// The stripped text.
pub fn Stripped::text(self : Stripped) -> String {
  self.text
}

///|
/// The removed stretches, in input order. Offsets are UTF-16 code units
/// of the input.
pub fn Stripped::removed(self : Stripped) -> Array[Removed] {
  self.removed.copy()
}

///|
/// The input offset that corresponds to `offset` in the stripped text: for
/// a kept character its own position, for the space that stands for a
/// removed stretch the start of that stretch, and for `text.length()` the
/// end of the input. Offsets outside the stripped text are clamped.
pub fn Stripped::original_offset(self : Stripped, offset : Int32) -> Int32 {
  let i = if offset < 0 {
    0
  } else if offset >= self.origin.length() {
    self.origin.length() - 1
  } else {
    offset
  }
  self.origin[i]
}

///|
fn is_ascii_alpha(c : Int32) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_ascii_digit(c : Int32) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_hex_letter(c : Int32) -> Bool {
  (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
fn is_ascii_alnum(c : Int32) -> Bool {
  is_ascii_alpha(c) || is_ascii_digit(c)
}

///|
/// Letters of any script, digits and `_`, by UTF-16 unit: every unit at
/// or above U+00C0 except punctuation and spaces counts, which keeps
/// hashtags in other languages whole.
fn is_word_unit(c : Int32) -> Bool {
  is_ascii_alnum(c) ||
  c == '_' ||
  (c >= 0xC0 && !is_js_space(c) && c != 0xD7 && c != 0xF7 && !is_cjk_punct(c))
}

///|
fn is_cjk_punct(c : Int32) -> Bool {
  (c >= 0x2000 && c <= 0x206F) ||
  (c >= 0x3000 && c <= 0x303F) ||
  (c >= 0xFF00 && c <= 0xFF0F) ||
  (c >= 0xFF1A && c <= 0xFF20)
}

///|
fn unit(text : String, i : Int32) -> Int32 {
  if i >= 0 && i < text.length() {
    text.unsafe_get(i).to_int()
  } else {
    -1
  }
}

///|
/// True when `text` at `i` starts with `prefix`, ignoring ASCII case.
fn starts_with_ci(text : String, i : Int32, prefix : String) -> Bool {
  if i + prefix.length() > text.length() {
    return false
  }
  for k in 0..<prefix.length() {
    let mut c = unit(text, i + k)
    if c >= 'A' && c <= 'Z' {
      c += 32
    }
    if c != prefix.unsafe_get(k).to_int() {
      return false
    }
  }
  true
}

///|
/// True when position `i` does not continue a word, so that a mention,
/// hashtag or address may start there.
fn at_word_start(text : String, i : Int32) -> Bool {
  let prev = unit(text, i - 1)
  prev < 0 || !(is_word_unit(prev) || prev == '@' || prev == '#' || prev == '.')
}

///|
/// End of a URL whose address starts at `i`: the run of non-space units,
/// without trailing sentence punctuation or an unmatched closing bracket.
fn url_end(text : String, i : Int32) -> Int32 {
  let mut end = i
  let mut open = 0
  while end < text.length() {
    let c = unit(text, end)
    if is_js_space(c) || c == '<' || c == '>' || c == '"' || c == '`' {
      break
    }
    if c == '(' {
      open += 1
    } else if c == ')' {
      if open == 0 {
        break
      }
      open -= 1
    }
    end += 1
  }
  while end > i {
    let c = unit(text, end - 1)
    if c == '.' ||
      c == ',' ||
      c == ';' ||
      c == ':' ||
      c == '!' ||
      c == '?' ||
      c == '\'' {
      end -= 1
    } else {
      break
    }
  }
  end
}

///|
fn match_url(text : String, i : Int32) -> Int32? {
  if !at_word_start(text, i) {
    return None
  }
  for scheme in ["https://", "http://", "ftp://", "www."] {
    if starts_with_ci(text, i, scheme) {
      let end = url_end(text, i + scheme.length())
      return if end > i + scheme.length() { Some(end) } else { None }
    }
  }
  None
}

///|
fn is_email_local(c : Int32) -> Bool {
  is_ascii_alnum(c) || c == '.' || c == '_' || c == '%' || c == '+' || c == '-'
}

///|
/// An e-mail address whose `@` is at `at`: returns its start and end.
fn match_email(text : String, at : Int32) -> (Int32, Int32)? {
  let mut start = at
  while start > 0 && is_email_local(unit(text, start - 1)) {
    start -= 1
  }
  if start == at || unit(text, start) == '.' {
    return None
  }
  let mut end = at + 1
  let mut last_dot = -1
  while end < text.length() {
    let c = unit(text, end)
    if is_ascii_alnum(c) || c == '-' {
      end += 1
    } else if c == '.' && is_ascii_alnum(unit(text, end + 1)) {
      last_dot = end
      end += 1
    } else {
      break
    }
  }
  if last_dot < 0 || end - last_dot - 1 < 2 {
    return None
  }
  for k in (last_dot + 1)..<end {
    if !is_ascii_alpha(unit(text, k)) {
      return None
    }
  }
  Some((start, end))
}

///|
/// A `@mention` or `#hashtag` starting at `i`: the end of its name.
fn match_tag(text : String, i : Int32, hashtag : Bool) -> Int32? {
  if !at_word_start(text, i) {
    return None
  }
  let mut end = i + 1
  let mut letter = false
  while end < text.length() {
    let c = unit(text, end)
    if (hashtag && is_word_unit(c)) ||
      (!hashtag && (is_ascii_alnum(c) || c == '_')) {
      letter = letter || !(is_ascii_digit(c) || c == '_')
      end += 1
    } else {
      break
    }
  }
  if end == i + 1 || (hashtag && !letter) {
    None
  } else {
    Some(end)
  }
}

///|
/// Index of `needle` in `text` at or after `from`, ignoring ASCII case.
fn find_ci(text : String, from : Int32, needle : String) -> Int32? {
  let mut i = from
  while i + needle.length() <= text.length() {
    if starts_with_ci(text, i, needle) {
      return Some(i)
    }
    i += 1
  }
  None
}

///|
/// Elements whose content is code or markup rather than prose.
let code_elements : Array[String] = ["code", "pre", "script", "style"]

///|
/// An HTML tag, comment or doctype at `i`. Returns the end and whether the
/// tag opens an element whose content is removed with it, in which case
/// the end is after the matching closing tag (or the end of the input).
fn match_html(text : String, i : Int32) -> (Int32, Markup)? {
  if starts_with_ci(text, i, "<!--") {
    let end = match find_ci(text, i + 4, "-->") {
      Some(k) => k + 3
      None => text.length()
    }
    return Some((end, HtmlTag))
  }
  let mut k = i + 1
  let closing = unit(text, k) == '/'
  if closing || unit(text, k) == '!' || unit(text, k) == '?' {
    k += 1
  }
  if !is_ascii_alpha(unit(text, k)) {
    return None
  }
  let name_start = k
  while is_ascii_alnum(unit(text, k)) ||
        unit(text, k) == '-' ||
        unit(text, k) == ':' {
    k += 1
  }
  let name = text
    .view(start_offset=name_start, end_offset=k)
    .to_owned()
    .to_lower()
  let next = unit(text, k)
  if !(next == '>' || next == '/' || is_js_space(next)) {
    return None
  }
  let mut quote = -1
  while k < text.length() {
    let c = unit(text, k)
    if quote >= 0 {
      if c == quote {
        quote = -1
      }
    } else if c == '"' || c == '\'' {
      quote = c
    } else if c == '>' {
      break
    } else if c == '<' || (c == '\n' && unit(text, k + 1) == '\n') {
      return None
    }
    k += 1
  }
  if k >= text.length() {
    return None
  }
  let end = k + 1
  if !closing && code_elements.contains(name) && unit(text, end - 2) != '/' {
    let close = match find_ci(text, end, "</" + name) {
      Some(c) =>
        match find_ci(text, c, ">") {
          Some(gt) => gt + 1
          None => text.length()
        }
      None => text.length()
    }
    return Some((close, Code))
  }
  Some((end, HtmlTag))
}

///|
/// An HTML character reference at `i`, `&name;`, `&#123;` or `&#x7B;`.
fn match_entity(text : String, i : Int32) -> Int32? {
  let mut k = i + 1
  if unit(text, k) == '#' {
    k += 1
    let hex = unit(text, k) == 'x' || unit(text, k) == 'X'
    if hex {
      k += 1
    }
    let digits = k
    while is_ascii_digit(unit(text, k)) || (hex && is_hex_letter(unit(text, k))) {
      k += 1
    }
    if k == digits {
      return None
    }
  } else {
    let name = k
    while is_ascii_alnum(unit(text, k)) {
      k += 1
    }
    if k == name || k - name > 32 {
      return None
    }
  }
  if unit(text, k) == ';' {
    Some(k + 1)
  } else {
    None
  }
}

///|
/// A Markdown code span or fenced block starting with the backtick at
/// `i`: the end after the closing run of as many backticks. An unclosed
/// fence of three or more runs to the end of the input; an unclosed single
/// backtick is not code.
fn match_code(text : String, i : Int32) -> Int32? {
  let mut run = 0
  while unit(text, i + run) == '`' {
    run += 1
  }
  let mut k = i + run
  while k < text.length() {
    if unit(text, k) == '`' {
      let mut n = 0
      while unit(text, k + n) == '`' {
        n += 1
      }
      if n == run {
        return Some(k + n)
      }
      k += n
    } else {
      k += 1
    }
  }
  if run >= 3 {
    Some(text.length())
  } else {
    None
  }
}

///|
/// Removes URLs, e-mail addresses, @mentions, #hashtags, HTML tags,
/// comments and character references, and code (Markdown code spans and
/// fences, and the content of HTML `code`, `pre`, `script` and `style`
/// elements) from `text`, which otherwise would count as words of the
/// text's language. Each removed stretch becomes one space; the result
/// maps its offsets back to `text` (see `Stripped::original_offset`).
pub fn strip_markup(text : String) -> Stripped {
  let out = StringBuilder()
  let origin = []
  let removed = []
  let mut i = 0
  let mut kept_from = 0
  let n = text.length()
  // Copies text[kept_from, upto) and records where each unit came from.
  let flush = (upto : Int32) => {
    out.write_substring(text, kept_from, upto - kept_from)
    for k in kept_from..<upto {
      origin.push(k)
    }
  }
  while i < n {
    let c = unit(text, i)
    let found : (Int32, Int32, Markup)? = match c {
      'h' | 'H' | 'f' | 'F' | 'w' | 'W' =>
        match_url(text, i).map(end => (i, end, Url))
      '@' =>
        match match_email(text, i) {
          Some((start, end)) if start >= kept_from => Some((start, end, Email))
          _ => match_tag(text, i, false).map(end => (i, end, Mention))
        }
      '#' => match_tag(text, i, true).map(end => (i, end, Hashtag))
      '<' => match_html(text, i).map(r => (i, r.0, r.1))
      '&' => match_entity(text, i).map(end => (i, end, HtmlEntity))
      '`' => match_code(text, i).map(end => (i, end, Code))
      _ => None
    }
    match found {
      Some((start, end, kind)) => {
        flush(start)
        out.write_char(' ')
        origin.push(start)
        removed.push({ start, end, kind, })
        i = end
        kept_from = end
      }
      None => i += 1
    }
  }
  flush(n)
  origin.push(n)
  { text: out.to_string(), removed, origin, }
}
