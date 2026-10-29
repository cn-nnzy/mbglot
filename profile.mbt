///|
/// A trigram profile: a named language, dialect or kind of text, given by
/// its most frequent trigrams, most frequent first. franc-min's built-in
/// languages have 300 (see `Profile::of_lang`); `Profile::train` makes one
/// from sample text. Profiles are compared by a `Classifier`.
pub struct Profile {
  priv name : String
  /// Trigram keys (see `pack`), most frequent first.
  priv grams : Array[Int64]
}

///|
/// Why a profile or a classifier could not be made.
pub(all) suberror ProfileError {
  /// The name is empty or contains a line break.
  BadName(String)
  /// The training text has no trigrams, or the saved profile none.
  NoTrigrams
  /// `size` must be positive.
  BadSize(Int32)
  /// A saved profile does not start with the header line.
  BadHeader
  /// Line `line` (1-based) of a saved profile is not a trigram of three
  /// UTF-16 code units, or repeats one.
  BadTrigram(Int32)
  /// A classifier needs at least one profile.
  NoProfiles
  /// Two profiles of a classifier have this name.
  DuplicateName(String)
} derive(Eq, Debug)

///|
fn check_name(name : String) -> Unit raise ProfileError {
  if name == "" || name.contains("\n") || name.contains("\r") {
    raise BadName(name)
  }
}

///|
/// A profile named `name` of the `size` most frequent trigrams of `text`,
/// counted as franc counts them (see `trigram-utils`): the text is
/// cleaned, lowercased and padded, and ties go to the trigram seen first.
/// franc-min's own profiles were made the same way from the Universal
/// Declaration of Human Rights, with 300 trigrams; a few thousand words of
/// typical text are enough for a usable profile.
pub fn Profile::train(
  name : String,
  text : String,
  size~ : Int32 = 300,
) -> Profile raise ProfileError {
  check_name(name)
  if size <= 0 {
    raise BadSize(size)
  }
  let counted = trigram_counts(text).to_array().mapi((i, t) => (t.0, t.1, i))
  if counted.is_empty() {
    raise NoTrigrams
  }
  counted.sort_by((a, b) => if a.1 != b.1 { b.1 - a.1 } else { a.2 - b.2 })
  if counted.length() > size {
    counted.truncate(size)
  }
  { name, grams: counted.map(t => t.0), }
}

///|
/// franc-min's profile of `lang` in `script`, named by its ISO 639-3
/// code. Without `script`, the language's first profile: Bosnian, Serbian,
/// Northern Uzbek, North Azerbaijani and Malay have one in Latin and one in
/// Cyrillic or Arabic script, and the Latin one comes first. `None` for a
/// language identified by its script alone (such as Japanese or Thai) or
/// without a profile in `script`.
pub fn Profile::of_lang(lang : Lang, script? : Script) -> Profile? {
  for entry in trigram_profiles {
    if script is Some(s) && s != entry.0 {
      continue
    }
    for profile in entry.1 {
      if profile.0 == lang {
        return Some({
          name: lang.code(),
          grams: profile.1.split("|").map(gram => key_of(gram)).collect(),
        })
      }
    }
  }
  None
}

///|
/// The profile's name.
pub fn Profile::name(self : Profile) -> String {
  self.name
}

///|
/// The profile's trigrams, most frequent first.
pub fn Profile::trigrams(self : Profile) -> Array[String] {
  self.grams.map(unpack)
}

///|
let profile_header : String = "mbglot profile 1"

///|
/// The profile as text, for saving: a header line, the name, then one
/// trigram per line, most frequent first. `Profile::parse` reads it back.
/// Trigrams never contain a line break, since the text they come from is
/// cleaned of whitespace other than single spaces.
pub fn Profile::save(self : Profile) -> String {
  let b = StringBuilder()
  b.write_string(profile_header)
  b.write_char('\n')
  b.write_string(self.name)
  b.write_char('\n')
  for key in self.grams {
    b.write_string(unpack(key))
    b.write_char('\n')
  }
  b.to_string()
}

///|
/// Reads a profile written by `Profile::save`. Line breaks may be `\r\n`.
pub fn Profile::parse(saved : String) -> Profile raise ProfileError {
  let lines = saved
    .split("\n")
    .map(line => line.trim_end(chars="\r").to_owned())
    .collect()
  if lines.last() == Some("") {
    lines.pop() |> ignore
  }
  if lines.length() < 2 || lines[0] != profile_header {
    raise BadHeader
  }
  let name = lines[1]
  check_name(name)
  let grams = []
  let seen : Set[Int64] = Set([])
  for i in 2..<lines.length() {
    let line = lines[i]
    if line.length() != 3 {
      raise BadTrigram(i + 1)
    }
    let key = key_of(line)
    if seen.contains(key) {
      raise BadTrigram(i + 1)
    }
    seen.add(key)
    grams.push(key)
  }
  if grams.is_empty() {
    raise NoTrigrams
  }
  { name, grams, }
}

///|
/// Compares texts with a set of profiles by franc's trigram distance.
/// Unlike `detect`, every profile competes whatever the script of the
/// text, and no pass for related languages applies: the ranking is
/// franc's method applied to the given profiles.
pub struct Classifier {
  priv profiles : Array[Profile]
  /// Trigram key -> (profile position, rank) pairs.
  priv postings : Map[Int64, Array[(Int32, Int32)]]
}

///|
/// A classifier for `profiles`, which must have distinct names.
pub fn Classifier::new(
  profiles : Array[Profile],
) -> Classifier raise ProfileError {
  if profiles.is_empty() {
    raise NoProfiles
  }
  let names : Set[String] = Set([])
  let postings : Map[Int64, Array[(Int32, Int32)]] = Map([])
  for i, profile in profiles {
    if names.contains(profile.name) {
      raise DuplicateName(profile.name)
    }
    names.add(profile.name)
    for rank, key in profile.grams {
      match postings.get(key) {
        Some(list) => list.push((i, rank))
        None => postings[key] = [(i, rank)]
      }
    }
  }
  { profiles: profiles.copy(), postings, }
}

///|
/// The names of the profiles, in the order given.
pub fn Classifier::names(self : Classifier) -> Array[String] {
  self.profiles.map(profile => profile.name)
}

///|
/// Every profile's name with a score between 0 and 1, best first, scored
/// as franc scores languages: the best scores 1.0 and the others are
/// scaled by their trigram distance relative to it; ties keep the order of
/// the profiles. Only the first 2048 UTF-16 code units are used. Empty
/// when the text is shorter than `min_length` code units or has no
/// trigrams.
pub fn Classifier::rank(
  self : Classifier,
  text : String,
  min_length~ : Int32 = 10,
) -> Array[(String, Double)] {
  if text.length() == 0 || text.length() < min_length {
    return []
  }
  let sample = if text.length() > max_sample_length {
    text.view(end_offset=max_sample_length).to_owned()
  } else {
    text
  }
  let grams = trigram_counts(sample)
  if grams.is_empty() {
    return []
  }
  let totals = FixedArray::make(
    self.profiles.length(),
    grams.length() * max_difference,
  )
  for key, count in grams {
    guard self.postings.get(key) is Some(list) else { continue }
    for posting in list {
      let (i, rank) = posting
      totals[i] += (count - rank - 1).abs() - max_difference
    }
  }
  let found = self.profiles.mapi((i, profile) => (profile.name, totals[i], i))
  found.sort_by((a, b) => if a.1 != b.1 { a.1 - b.1 } else { a.2 - b.2 })
  let min = found[0].1
  let max = sample.length() * max_difference - min
  found.map(d => {
    let score = 1.0 - (d.1 - min).to_double() / max.to_double()
    (d.0, if score.is_nan() { 0.0 } else { score })
  })
}

///|
/// The name of the best profile for `text`, or `None` when `rank` is
/// empty.
pub fn Classifier::classify(
  self : Classifier,
  text : String,
  min_length~ : Int32 = 10,
) -> String? {
  match self.rank(text, min_length~) {
    [] => None
    ranked => Some(ranked[0].0)
  }
}
