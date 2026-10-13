# mbglot

Offline language identification for [MoonBit](https://www.moonbitlang.com),
ported from [franc-min](https://github.com/wooorm/franc/tree/main/packages/franc-min)
6.2.0. No network access, no native dependencies; the same results on the
wasm, wasm-gc, js and native backends.

[Try it in your browser](https://cn-nnzy.github.io/mbglot/): the
[demo page](#browser-demo) runs mbglot compiled to JavaScript.

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
  ASCII punctuation, digits and whitespace become one space, the text is
  trimmed and lowercased like JavaScript's `toLowerCase` (Unicode 17.0.0
  tables, including `İ` and final sigma), padded with spaces and cut into
  trigrams of UTF-16 code units.
- Trigram profiles (internal): the 66 profiles of franc-min 6.2.0, 300
  trigrams each, generated into `profiles.mbt` by `tools/gen_profiles.mjs`.
  CI regenerates them from npm and fails if they differ from the committed
  file.
- `segments(text, options?) -> Array[Segment]`: splits a text that mixes
  languages into consecutive segments with their own detection. This is
  mbglot's own procedure on top of franc's scores (franc has no
  segmentation); see below.
- An evaluation package, `cn-nnzy/mbglot/eval`: accuracy, confusion
  counts and per-language precision, recall and F1 for any predictor over
  labelled samples (see [Measuring accuracy](#measuring-accuracy)).
- A command-line tool in `cmd/main`, a ticket-routing example in
  `examples/tickets` and a [browser demo](#browser-demo) in `demo`.

Not implemented: languages beyond franc-min's 76, and streaming input.
There is no release on mooncakes.io yet.

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
says so instead of guessing. With `--segments` it prints one line per
language segment (see [Mixed-language text](#mixed-language-text)):

```
$ moon run cmd/main -- --segments "Здравствуйте, заказ не пришёл. Hi, could you check the tracking number for order 4471 please? 谢谢，麻烦尽快处理一下这个问题。"
[0, 31)      bul  Bulgarian                not reliable Здравствуйте, заказ не пришёл.
[31, 94)     eng  English                  reliable     Hi, could you check the tracking numb...
[94, 110)    cmn  Mandarin Chinese         not reliable 谢谢，麻烦尽快处理一下这个问题。
```

The first sentence is Russian; franc-min's statistics prefer Bulgarian for
it, and the line says that the detection is not reliable.

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

### Browser demo

`demo/` is a web page that runs mbglot compiled to JavaScript: type or
paste text and it shows the detected language, the confidence, the five
best candidates and the text coloured by language segment, updated on
every keystroke. Nothing is sent to a server. It is published at
<https://cn-nnzy.github.io/mbglot/> by the `Demo` workflow
(`.github/workflows/pages.yml`) on every push to `main`, after a check
that the built page identifies a German sentence. To build and serve it
locally:

```
node tools/build_demo.mjs _site
python -m http.server -d _site
```

and open <http://localhost:8000>. The page calls one exported function,
`analyze(text)` in `demo/analyze.mbt`, which returns the detection, the
top candidates and the segments as JSON; segment offsets are UTF-16 code
units, so they index JavaScript strings directly.

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

```mbt check
///|
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

```mbt check
///|
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

## Mixed-language text

```mbt check
///|
test {
  let text = "Hello, my order has not arrived yet and I need it for Friday. " +
    "Hola, mi pedido no ha llegado todavía y lo necesito para el viernes."
  let parts = @mbglot.segments(text)
  assert_eq(parts.map(s => s.detection.unwrap().lang), [
    @mbglot.Eng,
    @mbglot.Spa,
  ])
  assert_eq(parts[1].start, 62)
}
```

`segments` cuts the text before the first letter after a sentence end
(`.`, `!`, `?`, `؟` and `۔` when followed by whitespace; newlines, `。`,
`！`, `？` and the danda always) and wherever the writing system changes
(Han and Kana count as one, so Japanese stays together). Each piece goes
through `detect`. A piece that cannot be identified on its own, because it
is shorter than `min_length` or has no letters, is joined to a neighbour,
preferably one in the same script, and identified again; neighbours in the
same language are then merged and identified again. Punctuation, spaces
and emoji stay with the piece before them.

Segments are contiguous and cover the whole input; `start` and `end` are
UTF-16 code unit offsets and `text` is that slice. An empty text gives no
segments, and a text with nothing identifiable gives one segment whose
`detection` is `None`. Abbreviations such as `e.g. ` cause an extra cut,
which is usually undone because the short piece is joined back. Sentences
inherit franc's accuracy, so short sentences in closely related languages
can still be misidentified; check `reliable` on each segment.

## Script detection

```mbt check
///|
test {
  assert_eq(
    @mbglot.detect_script("Привет, мир"),
    Some(@mbglot.Cyrillic),
  )
  assert_eq(@mbglot.detect_script("12:30 👍"), None)
}
```

Han ideographs count for both `Han` and `Kana`, as in franc: Chinese text
is `Han` (ties go to `Han`), while Japanese text that mixes kana and kanji
is `Kana`. Combining marks outside a script's own block (such as U+0301)
count for no script.

## Measuring accuracy

The `cn-nnzy/mbglot/eval` package scores any language predictor against
labelled samples. `evaluate(samples, predict)` returns a `Report` with
accuracy, the confusion counts, precision, recall and F1 per language,
macro F1, the most frequent mistakes, and Markdown tables of these
(`to_markdown`, `confusion_markdown`). A predictor returns `None` when it
declines to answer; that counts against recall and accuracy but not
precision, which is how a router that sends uncertain messages to manual
triage behaves.

```mbt check
///|
test {
  let samples : Array[@eval.Sample] = [
    {
      lang: Eng,
      text: "Thanks for the quick reply, the replacement arrived today.",
    },
    {
      lang: Deu,
      text: "Vielen Dank, die Ersatzlieferung ist heute angekommen.",
    },
  ]
  let report = @eval.evaluate(samples, text => {
    match @mbglot.detect(text) {
      Some(d) => Some(d.lang)
      None => None
    }
  })
  assert_eq(report.total(), 2)
  assert_eq(report.count(Deu, Some(Deu)), 1)
}
```

`moon run eval/run` evaluates mbglot on a small labelled set (the ticket
example and the demo samples), once counting every detection and once
counting only reliable ones.

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

CI runs the same commands on Ubuntu 24.04, Windows Server 2025 and macOS
15 with a pinned MoonBit toolchain (moonc 0.10.14+7d59c7ec9, set by
`MOONBIT_INSTALL_VERSION` in `.github/workflows/ci.yml`), because newer
releases may format code differently. The code examples in this README
are `mbt check` blocks of `README.mbt.md`, so `moon test` compiles and runs
them on every target (`README.md` is a symbolic link to it). The
generators for committed data files are described in
[tools/README.md](tools/README.md).

`python tools/loc.py` counts lines of MoonBit by kind: library code,
programs and demos, tests, and generated or transcribed data.

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
