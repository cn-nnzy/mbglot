# mbglot

Offline language identification for [MoonBit](https://www.moonbitlang.com),
ported from [franc-min](https://github.com/wooorm/franc/tree/main/packages/franc-min)
6.2.0. No network access, no native dependencies; the same results on the
wasm, wasm-gc, js and native backends.

## Status

Milestone 1 is complete. Implemented:

- `detect(text, options?) -> Detection?` and
  `rank(text, options?) -> Array[(Lang, Double)]`, giving the same
  rankings and scores as franc-min 6.2.0 (checked by a golden test, see
  below), with `Options` for allow / deny lists and a minimum length, and a
  `reliable` flag.
- `Lang`: the 76 languages of franc-min 6.2.0, with `code()` (ISO 639-3),
  `name()` (English), `Lang::from_code` and `Lang::all()`.
- `Script`: the 20 writing systems franc-min distinguishes, with `name()`
  and `Script::all()`.
- `detect_script(text) -> Script?`: the writing system used by most
  characters, with franc-min's Unicode ranges, sample limit (first 2048
  UTF-16 code units) and tie order. Returns `None` for text with no
  letters of a supported script (empty, digits, punctuation, emoji).
- Trigram extraction matching `trigram-utils` 2.0.1 (internal): runs of
  ASCII punctuation, digits and whitespace become one space, the text is trimmed and lowercased like JavaScript's
  `toLowerCase` (Unicode 17.0.0 tables, including `İ` and final sigma),
  padded with spaces and cut into trigrams of UTF-16 code units.
- Trigram profiles (internal): the 66 profiles of franc-min 6.2.0, 300
  trigrams each, generated into `profiles.mbt` by `tools/gen_profiles.mjs`.
  CI regenerates them from npm and fails if they differ from the committed
  file.

- A command-line tool in `cmd/main` and a ticket-routing example in
  `examples/tickets`.

Not implemented: languages beyond franc-min's 76, detecting several
languages within one text, and streaming input. There is no release on
mooncakes.io yet.

## Usage

Add the module to your project:

```
moon add cn-nnzy/mbglot
```

and import the package in your `moon.pkg`:

```
import {
  "cn-nnzy/mbglot" @mbglot,
}
```

`moon add` works once the module is published; until then, depend on a
checkout of this repository.

### Command line

```
$ moon run cmd/main -- "Hola, mi pedido llegó incompleto y falta una de las piezas."
language:   Spanish (spa)
script:     Latin
confidence: 0.226 (reliable)
top 5:
  1. spa  Spanish                  1.000
  2. ita  Italian                  0.774
  3. por  Portuguese               0.702
  4. lin  Lingala                  0.689
  5. fra  French                   0.687
```

Without an argument it prints a usage line; for text it cannot identify it
says so instead of guessing.

### Example: routing support tickets

`examples/tickets` sends each message to a language queue when the
detection is reliable and to manual triage otherwise:

```
$ moon run examples/tickets
#1001  support-en  (eng English)
#1002  triage  (spa Spanish, not reliable)
#1003  support-fr  (fra French)
#1004  support-de  (deu German)
#1005  triage  (spa Spanish, not reliable)
#1006  triage  (bul Bulgarian, not reliable)
#1007  support-zh  (cmn Mandarin Chinese)
#1008  support-ja  (jpn Japanese)
#1009  support-ar  (arb Standard Arabic)
#1010  triage  (tur Turkish, not reliable)
#1011  triage  (no language)
#1012  triage  (por Portuguese, not reliable)
```

Tickets 1005 (Portuguese) and 1006 (Russian) are misidentified by
franc-min's statistics, which is why the example only trusts reliable
detections: both are flagged as not reliable and go to triage.

## Languages

franc-min advertises 82 languages; it counts a language once per script.
Merging those gives 76 distinct ISO 639-3 codes:

- 61 languages told apart by trigram profiles within the Latin, Cyrillic,
  Arabic and Devanagari scripts (66 profiles, since Bosnian, Serbian,
  Northern Uzbek, North Azerbaijani and Malay each have two scripts).
- 15 languages identified by a script used only by them: Mandarin Chinese
  (Han), Japanese (Kana), Korean (Hangul), Bengali, Telugu, Tamil,
  Gujarati, Kannada, Malayalam, Burmese, Panjabi (Gurmukhi), Amharic
  (Ethiopic), Thai, Sinhala and Modern Greek. Javanese script also maps to
  Javanese, which has a Latin profile as well.

## Detecting a language

```moonbit
test {
  let text = "Hola, mi pedido llegó incompleto y falta una de las piezas."
  let detection = @mbglot.detect(text).unwrap()
  assert_eq(detection.lang, @mbglot.Spa)
  assert_eq(detection.lang.name(), "Spanish")
  assert_eq(detection.script, @mbglot.Latin)
  assert_eq(@mbglot.detect("12:30 👍"), None)
}
```

`detect` returns `None` instead of guessing when the text is empty, has no
letters of a supported script (whitespace, digits, punctuation, emoji), or
is shorter than `min_length` (default 10 UTF-16 code units, as in franc).

`rank` returns every candidate of the dominant script with franc's score:
the best language scores 1.0 and the others are scaled by trigram
distance relative to it. Equal scores keep franc's language order. For a
script used by one language only (Han, Hangul, Thai, ...) the result has
that single language with 1.0.

`Detection.confidence` is the margin between the best and second-best
score (1.0 with a single candidate). `reliable` is true when the margin is
at least `reliable_min_margin` (0.15) and the text is at least
`reliable_min_length` (30) UTF-16 code units long. On franc's own test
fixtures, cut to lengths from 20 to 1000 code units, every detection with a
margin of 0.14 or more was correct, and most mistakes came from texts of 20
to 35 code units (mostly Bosnian, Croatian and Serbian). Those fixtures are
the texts franc was trained on, so treat the flag as a heuristic.

### Options

```moonbit
test {
  let options = @mbglot.Options::new(allow=[@mbglot.Eng, @mbglot.Por])
  let ranked = @mbglot.rank("Hola, mi pedido llegó incompleto.", options~)
  assert_eq(ranked.map(r => r.0), [@mbglot.Por, @mbglot.Eng])
}
```

`Options::new(allow?, deny?, min_length? = 10)` raises `OptionsError`
instead of silently ignoring a setting that cannot work: an empty `allow`
list, a language both allowed and denied, a `deny` list naming every
language, or a negative `min_length`. Allowing only languages of another
script than the text's makes `detect` return `None`.

## Script detection

```moonbit
test {
  assert_eq(@mbglot.detect_script("Привет, мир"), Some(@mbglot.Cyrillic))
  assert_eq(@mbglot.detect_script("12:30 👍"), None)
}
```

Han ideographs count for both `Han` and `Kana`, as in franc: Chinese text
is `Han` (ties go to `Han`), while Japanese text that mixes kana and kanji
is `Kana`. Combining marks outside a script's own block (such as U+0301)
count for no script.

## Development

```
moon fmt
moon info
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon test --target js      # needs Node.js
moon test --target native  # needs a C compiler
```

CI runs the same commands on Ubuntu, Windows and macOS. The generators
for committed data files are described in [tools/README.md](tools/README.md).

### franc parity

`golden_wbtest.mbt` holds franc-min 6.2.0's `francAll` output for the 82
fixtures of franc's own test suite in languages franc-min supports, and
for the hand-written cases in `tools/golden_samples.json` (short and long
texts, mixed scripts, emoji, the sample limit, options). The test compares
mbglot's ranking and every score for exact equality. It is generated
under Node.js with:

```
npm install --prefix "$TMP/franc" --no-save --ignore-scripts franc-min@6.2.0
curl -fsSL -o "$TMP/fixtures.js" https://raw.githubusercontent.com/wooorm/franc/3f9f0b51a96c5df32a407dad865a3011ac0fa2d1/test/fixtures.js
node tools/gen_golden.mjs "$TMP/franc/node_modules/franc-min" "$TMP/fixtures.js" golden_wbtest.mbt
moon fmt
```

The `franc-min data` CI job runs these commands on every push and fails
if the result differs from the committed file.

## License

MIT, see [LICENSE](LICENSE). Data and algorithm come from franc-min
(MIT); the case tables come from the Unicode Character Database (Unicode
License V3). See [NOTICE](NOTICE).
