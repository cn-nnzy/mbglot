# mbglot

Offline language identification for [MoonBit](https://www.moonbitlang.com),
ported from [franc-min](https://github.com/wooorm/franc/tree/main/packages/franc-min)
6.2.0. No network access, no native dependencies; the same results on the
wasm, wasm-gc, js and native backends.

[Try it in your browser](https://cn-nnzy.github.io/mbglot/): the
[demo page](#browser-demo) runs mbglot compiled to JavaScript.

## At a glance

```mbt check
///|
test {
  let d = @mbglot.detect(
    "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio.",
  ).unwrap()
  assert_eq(d.lang, @mbglot.Por) // franc-min alone says Spanish
  assert_eq(d.lang.bcp47(), "pt")
  assert_true(d.reliable)
}
```

| Held-out benchmark | franc-min's ranking | mbglot (default) |
|---|---:|---:|
| Accuracy, Tatoeba test half (2,761 texts) | 77.2% | 82.8% |
| Accuracy, FLORES-200 devtest (2,720 texts) | 89.2% | 92.0% |
| Answered as `reliable`, Tatoeba test half | 39.0% | 58.7% |

The figures come from [eval/results.md](eval/results.md), which CI
regenerates; `tools/readme_tables.py` keeps this table and the copies
further down in step with it, and CI fails if they differ. In
`Mode::Franc` the rankings and scores are franc-min's, checked by a
golden test, and `detect` runs about 2.3 times as fast as franc-min on
the same Node.js ([Speed](#speed)). Beyond franc, mbglot offers language
segments for mixed text, markup removal, an explanation of each
decision, streaming input, trained profiles, BCP 47 tags, a command-line
tool with JSON output, and all 186 of franc's languages in a separate
package.

## Status

Implemented:

- `detect(text, options?) -> Detection?` and
  `rank(text, options?) -> Array[(Lang, Double)]`, with `Options` for
  allow / deny lists and a minimum length, and a `reliable` flag. In
  `Mode::Franc` they give the same rankings and scores as franc-min 6.2.0
  (checked by a golden test, see below); the default `Mode::Enhanced`
  removes markup first and settles closely related languages by their
  letters and common words (see [Related languages](#related-languages)).
- `Detector::new(options?)`: the same `detect`, `rank` and `segments`
  for a stream of texts, with the options worked out once (see
  [Speed](#speed)).
- `Lang`: the 76 languages of franc-min 6.2.0, with `code()` (ISO 639-3),
  `name()` (English), `native_name()`, `iso639_1()`, `bcp47()`,
  `speakers()`, `Lang::from_code`, `Lang::from_bcp47` and `Lang::all()`
  (see [Languages](#languages)).
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
- `Profile::train` and `Classifier`: profiles trained from sample text,
  saved as plain text and compared with franc's method, alone or with
  the built-in ones (see [Custom profiles](#custom-profiles)).
- `cn-nnzy/mbglot/full`: franc 6.2.0 with all its languages (see
  [All of franc's languages](#all-of-francs-languages)).
- `Accumulator`: the language of a stream fed in chunks, without
  re-reading earlier chunks (see [Streams](#streams)).
- `explain(text, options?)`: the steps that decided a detection and the
  trigrams that weigh for and against it (see
  [Why this language](#why-this-language)).
- `chinese_variant(text)`: simplified or traditional Chinese, and kana
  and Hangul shares that settle Chinese, Japanese and Korean (see
  [Chinese, Japanese and Korean](#chinese-japanese-and-korean)).
- `strip_markup(text)`: removes URLs, e-mail addresses, mentions,
  hashtags, HTML and code before detection, with a map back to the
  original offsets (see [Markup](#markup)). On by default.
- An evaluation package, `cn-nnzy/mbglot/eval`: accuracy, confusion
  counts and per-language precision, recall and F1 for any predictor over
  labelled samples (see [Measuring accuracy](#measuring-accuracy)), and a
  public benchmark on 5,541 Tatoeba sentences in 72 languages and
  2,720 FLORES-200 sentences in 68 (see [Benchmark](#benchmark)).
- A command-line tool in `cmd/main` with JSON output and a mode for
  files of one text per line, a ticket-routing example in
  `examples/tickets` and a [browser demo](#browser-demo) in `demo`.

All 186 of franc's languages are in the `full` package; the enhanced
passes cover franc-min's 76.
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
confidence: 0.506 (reliable)
runner-up:  Italian (ita), margin 0.226
top 5:
  1. spa  Spanish                  1.000
  2. ita  Italian                  0.774
  3. por  Portuguese               0.702
  4. lin  Lingala                  0.689
  5. fra  French                   0.687
```

Without a text it prints a usage error (`--help` lists the options); for
text it cannot identify it says so instead of guessing. With `--segments`
it prints one line per language segment (see
[Mixed-language text](#mixed-language-text)):

```
$ moon run cmd/main -- --segments "Здравствуйте, заказ не пришёл. Hi, could you check the tracking number for order 4471 please? 谢谢，麻烦尽快处理一下这个问题。"
[0, 31)      rus  Russian                  reliable     Здравствуйте, заказ не пришёл.
[31, 94)     eng  English                  reliable     Hi, could you check the tracking numb...
[94, 110)    cmn  Mandarin Chinese         reliable     谢谢，麻烦尽快处理一下这个问题。
```

franc-min's statistics alone prefer Bulgarian for the first sentence; the
pass for [related languages](#related-languages) settles Russian from its
letters and words, and that evidence makes the detection reliable
although franc's margin is small.

`--file PATH` identifies every line of a file and prints one
tab-separated result per line: the line number, the language, the
confidence and whether it is reliable, or dashes when nothing was
detected. Output line N always belongs to input line N:

```
$ moon run cmd/main -- --file messages.txt
1	eng	0.680	reliable
2	-	-	-
3	fra	0.263	reliable
4	bos	0.040	not reliable
```

`--json` prints the same as JSON, one object per line with `--file`
(JSON Lines), with the margin and the runner-up:

```
$ moon run cmd/main -- --json --top 2 "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio."
{"detection":{"lang":"por","bcp47":"pt","name":"Portuguese","script":"Latin","confidence":0.428,"margin":0.068,"reliable":true,"runner_up":"spa"},"top":[{"lang":"por","score":1},{"lang":"spa","score":0.932}]}
```

`--explain` adds the steps that decided the language and the trigrams
that weigh most for and against it (see
[Why this language](#why-this-language)). `--top N` sets how many
candidates are listed (5 for a text, none for a
file), `--allow` and `--deny` take language tags or ISO 639 codes
separated by commas (`--allow en,fr,deu`), `--mode franc` turns off the enhanced passes and
`--min-length` sets the minimum text length. Wrong options give a message
and exit status 2; a file that cannot be read gives exit status 1. The
tool reads files with `moonbitlang/x`; MoonBit has no portable way to
read standard input yet, so there is no stdin mode.

### Example: routing support tickets

`examples/tickets` sends each message to a language queue when the
detection is reliable and to manual triage otherwise:

```
$ moon run examples/tickets
#1001  support-en  (eng English)
#1002  support-es  (spa Spanish)
#1003  support-fr  (fra French)
#1004  support-de  (deu German)
#1005  support-pt  (por Portuguese)
#1006  support-ru  (rus Russian)
#1007  support-zh  (cmn Mandarin Chinese)
#1008  support-ja  (jpn Japanese)
#1009  support-ar  (arb Standard Arabic)
#1010  triage  (tur Turkish, not reliable)
#1011  triage  (no language)
#1012  triage  (por Portuguese, not reliable)
```

franc-min's statistics alone take ticket 1005 for Spanish and 1006 for
Bulgarian. The pass for [related languages](#related-languages) gets both
right, and the letters and words that decided it count toward the
confidence, so both are routed. The Turkish ticket is right too, but
franc's margin is small and few Turkish words are known, so it goes to
triage with the two messages that have too little text.

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

Each `Lang` has its ISO 639-3 `code()`, an English `name()`, a
`native_name()` (`Deutsch`, `日本語`), `speakers()` in millions as franc-min
lists them, `iso639_1()` and `bcp47()`. Languages that are the main
member of a macrolanguage take its two-letter code, as they are usually
tagged (Mandarin `zh`, Standard Arabic `ar`, Iranian Persian `fa`,
Malay `ms`); languages without a two-letter code keep their three-letter
one (`ceb`). `Lang::from_bcp47` reads the language of a tag such as an
`Accept-Language` entry or a locale, ignoring script and region:

```mbt check
///|
test {
  assert_eq(@mbglot.Lang::from_bcp47("pt-BR"), Some(@mbglot.Por))
  assert_eq(@mbglot.Lang::from_bcp47("zh-Hant-TW"), Some(@mbglot.Cmn))
  assert_eq(@mbglot.Lang::from_bcp47("zh-yue"), None)
  assert_eq(@mbglot.Cmn.bcp47(), "zh")
  assert_eq(@mbglot.Ceb.bcp47(), "ceb")
  assert_eq(@mbglot.Rus.native_name(), "русский")
}
```

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

`rank` returns every candidate of the dominant script with franc's score
(in the default mode, after the pass for
[related languages](#related-languages)):
the best language scores 1.0 and the others are scaled by trigram
distance relative to it. Equal scores keep franc's language order. For a
script used by one language only (Han, Hangul, Thai, ...) the result has
that single language with 1.0.

`Detection.margin` is the gap between the best and second-best score
(1.0 with a single candidate) and `runner_up` the second language.
`confidence` is the margin in `Mode::Franc`. In `Mode::Enhanced` it adds
0.04 for every letter or common word that favours the detected language
over the runner-up (see [Related languages](#related-languages) and
[Short texts](#short-texts)), up to 1.0. It ranks detections; it is not
a probability.

`reliable` says whether to act on a detection without review:

- in `Mode::Franc`, the margin is at least `reliable_min_margin` (0.15)
  and the text has at least `reliable_min_length` (30) UTF-16 code units;
- in `Mode::Enhanced`, the confidence is at least
  `reliable_min_confidence` (0.18), or `short_reliable_min_confidence`
  (0.4) for texts under 30 code units, and the runner-up is not a related
  language that the text gives no reason to rule out (Indonesian against
  Malay with only shared words, for example).

The enhanced weights and thresholds were chosen on the dev half of the
[benchmark](#benchmark). On the held-out test half they make 58.7% of
detections reliable instead of 39.0%, and 36.4% of short sentences
instead of 2.6%, with reliable precision 98.4%.

### Options

```mbt check
///|
test {
  let options = @mbglot.Options::new(allow=[@mbglot.Eng, @mbglot.Por])
  let ranked = @mbglot.rank("Hola, mi pedido llegó incompleto.", options~)
  assert_eq(ranked.map(r => r.0), [@mbglot.Por, @mbglot.Eng])
}
```

`Options::new(allow?, deny?, min_length? = 10, mode? = Enhanced, strip_markup?)`
raises `OptionsError`
instead of silently ignoring a setting that cannot work: an empty `allow`
list, a language both allowed and denied, a `deny` list naming every
language, or a negative `min_length`. Allowing only languages of another
script than the text's makes `detect` return `None`.

For many texts with the same options, build a `Detector` once; its
`detect`, `rank` and `segments` give the same results as the free
functions:

```mbt check
///|
test {
  let detector = @mbglot.Detector::new(
    options=@mbglot.Options::new(allow=[Eng, Fra, Deu]),
  )
  let langs = [
    "Where is my parcel?", "Où est mon colis ?", "Wo ist mein Paket?",
  ].map(text => detector.detect(text).map(d => d.lang))
  assert_eq(langs, [Some(Eng), Some(Fra), Some(Deu)])
}
```

### Related languages

franc ranks languages by trigram statistics, which often cannot tell
closely related languages apart in short texts. In the default
`Mode::Enhanced`, when franc's best language belongs to one of these
groups, a second pass counts letters and common words that only some
members use:

- Spanish and Portuguese (`ñ`, `¿` against `ã`, `õ`, `ç`, `lh`, `nh`;
  articles and pronouns);
- Russian, Ukrainian, Belarusian, Bulgarian, Serbian, Kazakh and Bosnian in
  Cyrillic (`ы`, `э`, `ё`; `ї`, `є`, `ґ`; `ў`; `ђ`, `ј`, `љ`, `њ`, `ћ`, `џ`;
  `ә`, `қ`, `ң`, `ө`, `ұ`, `ү`; and common words such as Bulgarian `е`,
  `са`, `ще`, `това`);
- Croatian, Serbian and Bosnian in Latin script (words such as `tko`,
  `ko`, `što`, `šta`, ekavian and ijekavian forms);
- Indonesian and Malay, Rundi and Kinyarwanda, Tagalog and Cebuano
  (common words, and `cy`, `jy` against `vy`);
- Standard Arabic, Persian, Urdu, Saraiki, Sorani Kurdish and Pashto in
  Arabic script (letters such as `ة`, `ڕ`, `ێ`, `ە`, `ټ`, `ښ`, `ٹ`, `ے`,
  `ٻ`, `ڄ`, and common words).

When some members have more evidence than franc's choice, the one franc
ranks highest among them moves to the top and swaps scores with franc's
choice, so the scores and the margin stay franc's, and the deciding
letters and words add to the confidence; without such evidence the
ranking is left alone. Groups belong to a script: Serbian and Bosnian
are settled among the Cyrillic languages in Cyrillic text (Serbian by
`ђ`, `ћ`, `ј` and ekavian words such as `време`, Bosnian by ijekavian
ones) and with Croatian in Latin text, where words such as `znanstvenici`
against `naučnici`, Croatian month names and `općina` against `opština`
count too. franc-min only has a profile for Kurdish in Latin script, so
Sorani in Arabic script is recognised by this pass alone. Norwegian and Danish are not among
franc-min's languages. The [benchmark](#benchmark) shows the effect;
`Mode::Franc` turns the pass off.

When the text holds nothing that tells the best language from the
runner-up, a related language whose score is within 0.12 of the best may
still take first place: each such candidate gets 0.1 times the logarithm
of its number of speakers (`Lang::speakers`, the figures franc-min lists),
and the highest total wins. This breaks near ties toward the language a
message is more likely to be in; no letter or word is outweighed by it.
The window and weight were chosen on the dev half of the
[benchmark](#benchmark), where every language is equally frequent.
Hindi, Bhojpuri, Maithili and Magahi get no prior: a pull toward Hindi
helped on Tatoeba, which has no Magahi, but cost more on the FLORES-200
dev set, where the four are equally frequent.

### Short texts

A text of a few words gives franc too few trigrams. In `Mode::Enhanced`,
texts shorter than `short_text_length` (40 UTF-16 code units, after
markup removal) also count very common words (articles, pronouns,
prepositions, auxiliaries) of 24 languages: English, Spanish, Portuguese,
French, German, Italian, Dutch, Polish, Czech, Swedish, Hungarian,
Romanian, Turkish, Indonesian, Malay, Vietnamese, Tagalog, Swahili,
Croatian, Serbian, Bosnian, Russian, Ukrainian and Bulgarian. Each such
word adds 0.1 to its language's score among franc's candidates, and the
candidate with the highest total moves to the top. One word lifts a
language over close competitors but not over ones far behind, and
languages without a list are scored by franc alone.

On the whole benchmark, before it was split into dev and test halves,
this raised accuracy on short sentences from 68.3% (with
the pass for related languages alone) to 71.2%, and on 31 to 80 code
units, which include texts under 40, from 84.3% to 85.4%. The weight was
chosen on all of it (0.02 to 0.25 tried, with gains levelling off above
0.1), so the test half does not hide it, and other texts may gain less. The words that
lift a language also count toward its `confidence`, so a short text with
two or three of them can be `reliable`. A word shared by several languages can also mislead: in
`je suis très fatigué` French is far down franc's list, and `je`, which
is also Croatian, lifts Croatian over franc's English.

```mbt check
///|
test {
  // franc's trigrams alone prefer Komi for these three Russian words.
  let franc = @mbglot.Options::new(mode=Franc)
  assert_eq(
    @mbglot.detect("это мой дом", options=franc).map(d => d.lang),
    Some(@mbglot.Koi),
  )
  assert_eq(
    @mbglot.detect("это мой дом").map(d => d.lang),
    Some(@mbglot.Rus),
  )
}
```

```mbt check
///|
test {
  let text = "Здравствуйте! После оплаты подписка так и не активировалась, а деньги списались."
  assert_eq(@mbglot.detect(text).map(d => d.lang), Some(@mbglot.Rus))
  let franc = @mbglot.Options::new(mode=Franc)
  assert_eq(
    @mbglot.detect(text, options=franc).map(d => d.lang),
    Some(@mbglot.Bul),
  )
}
```

### Chinese, Japanese and Korean

franc counts every Han ideograph as kana too, so a Chinese text with a
single kana, such as の in a shop name, comes out as Japanese, and Korean
that mixes in hanja comes out as Chinese when the hanja outnumber the
Hangul. In `Mode::Enhanced` a text in Han or kana is Japanese only when
kana make up at least a tenth of its CJK characters, and Korean when
Hangul makes up at least a fifth of its Hangul and Han characters.
`segments` keeps Han, kana and Hangul in one piece, so Korean with hanja
or Japanese with kanji is not cut at every change of script.

`chinese_variant(text)` tells simplified from traditional Chinese by
about 120 common characters that differ between the two standards (such
as 们/們, 这/這, 国/國), and returns `None` when the text has none of them
or as many of each. It is a hint for picking a font or a locale such as
`zh-Hans` or `zh-Hant`; the [browser demo](#browser-demo) shows it for
Chinese text.

```mbt check
///|
test {
  let text = "我们公司的产品在“美味の店”有售，欢迎大家来购买。"
  assert_eq(@mbglot.detect(text).map(d => d.lang), Some(@mbglot.Cmn))
  let franc = @mbglot.Options::new(mode=Franc)
  assert_eq(
    @mbglot.detect(text, options=franc).map(d => d.lang),
    Some(@mbglot.Jpn),
  )
  assert_eq(@mbglot.chinese_variant(text), Some(Simplified))
  assert_eq(
    @mbglot.chinese_variant("請幫忙查一下物流資訊，謝謝。"),
    Some(Traditional),
  )
}
```

### Markup

Messages from chat, e-mail and issue trackers carry addresses, handles
and code whose words are not in the message's language. By default
`detect`, `rank` and `segments` first remove URLs, e-mail addresses,
`@mentions`, `#hashtags` (with at least one letter, in any script), HTML
tags, comments and character references, Markdown code spans and fences,
and the content of HTML `code`, `pre`, `script` and `style` elements.
`min_length` and the `reliable` flag then apply to the text that is left,
so a message that is only a link is not identified.

```mbt check
///|
test {
  let text = "Il mio ordine non è arrivato " +
    "https://www.example.com/the/order/status/page/for/customers/with/questions"
  assert_eq(@mbglot.detect(text).map(d => d.lang), Some(@mbglot.Ita))
  let raw = @mbglot.Options::new(strip_markup=false)
  assert_eq(
    @mbglot.detect(text, options=raw).map(d => d.lang),
    Some(@mbglot.Eng),
  )
}
```

`strip_markup(text)` does the removal on its own. Each removed stretch
becomes one space, `removed()` lists what was removed and where, and
`original_offset` maps an offset in the stripped text back to the input.
`segments` uses that map, so its offsets and texts are slices of the
original input, markup included: a removed stretch stays in the segment
before it. `strip_markup=false` turns the step off. It is on by default in
`Mode::Enhanced` and off in `Mode::Franc`, which reproduces franc.

```mbt check
///|
test {
  let s = @mbglot.strip_markup("Merci @dana <b>!</b>")
  assert_eq(s.text(), "Merci    ! ")
  assert_eq(s.removed().map(r => r.kind), [Mention, HtmlTag, HtmlTag])
  assert_eq(s.original_offset(6), 6) // the space for @dana
  assert_eq(s.original_offset(9), 15) // the "!"
}
```

## Why this language

`explain(text, options?)` (or `Detector::explain`) returns the detection
together with the steps that decided it and the trigrams behind franc's
part:

- `steps`: franc's choice by trigram distance (`Trigrams`), then each pass
  of `Mode::Enhanced` that changed the language at the top: the shares of
  kana, Han and Hangul (`ScriptShare`), common words in a short text
  (`CommonWords`), letters and words that set a related language apart
  (`RelatedLanguages`, with only the clues that the language franc chose
  lacks) and a near tie broken by number of speakers (`NearTie`);
- `trigrams`: every trigram of the text that weighs differently for the
  detected language and the runner-up, with its count, its rank in both
  profiles and the difference it makes to franc's distance, strongest
  first.

```mbt check
///|
test {
  let why = @mbglot.explain(
    "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio.",
  )
  assert_eq(why.steps, [Trigrams(Spa), RelatedLanguages(Por, ["ç", "o", "do"])])
  assert_eq(why.trigrams[0].trigram, " do")
}
```

The command line prints the same with `--explain`, and the browser demo
shows the steps under the detection:

```
$ moon run cmd/main -- --explain --top 0 "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio."
language:   Portuguese (por)
script:     Latin
confidence: 0.428 (reliable)
runner-up:  Spanish (spa), margin 0.068
why:
  trigram statistics rank Spanish (spa) first
  letters and words that set Portuguese (por) apart from a related language: ç, o, do
trigrams for por over spa: " do" +233, "ido" +103, "o e" +101, "do " +87, "ntr" +51
trigrams for spa over por: "ere" -290, "der" -286, " en" -269, "ant" -145, "ari" -86
```

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
which is usually undone because the short piece is joined back. Short
sentences in closely related languages can still be misidentified; check
`reliable` on each segment.

## Custom profiles

franc's method works for any set of trigram profiles. `Profile::train`
makes one from sample text, the way franc-min's own were made from the
Universal Declaration of Human Rights, so a language franc-min lacks, a
dialect, or the style of your own messages can be added. A `Classifier`
ranks texts against any mix of trained and built-in (`Profile::of_lang`)
profiles by franc's trigram distance, without the passes of
`Mode::Enhanced`:

```mbt check
///|
test {
  let esperanto = @mbglot.Profile::train(
    "epo",
    "Saluton, mia nomo estas Petro kaj mi loĝas en granda urbo. " +
    "Mi tre ŝatas legi librojn kaj promeni en la parko kun mia hundo. " +
    "Hodiaŭ la vetero estas bela, do ni iros al la maro. " +
    "Ĉu vi volas veni kun ni? Ni manĝos fiŝojn kaj trinkos kafon.",
  )
  let profiles = [@mbglot.Eng, @mbglot.Spa, @mbglot.Ita].map(lang => {
    @mbglot.Profile::of_lang(lang).unwrap()
  })
  profiles.push(esperanto)
  let classifier = @mbglot.Classifier::new(profiles)
  assert_eq(
    classifier.classify("Ĉu vi scias, kie estas la stacidomo?"),
    Some("epo"),
  )
  // A profile saves to plain text and reads back.
  let saved = esperanto.save()
  assert_eq(@mbglot.Profile::parse(saved).trigrams(), esperanto.trigrams())
}
```

Profiles trained on text like the text to identify can beat the
built-in ones. The [benchmark](#benchmark) trains 300-trigram profiles
for its 39 Latin-script languages on the dev half and compares them with
franc-min's on the test half, both with trigram distance alone:

| Profiles | Languages | Samples | Accuracy | Macro F1 |
|---|---:|---:|---:|---:|
| franc-min | 39 | 1469 | 70.1% | 66.4% |
| trained on the dev half | 39 | 1469 | 84.8% | 80.9% |

Keep the default of 300 trigrams: in a trial on the same data, 1,000 gave
49.4% and 3,000 gave 35.3%, because franc's distance charges a fixed 300
for every trigram a profile lacks and compares counts with ranks, which
suits short profiles. A `Classifier` with franc-min's profiles of the
languages that `rank` lists gives franc's scores, which a test checks.

## Streams

An `Accumulator` identifies text that arrives in chunks, such as the
messages of a chat or the lines of a long file, without reading earlier
chunks again. It keeps what detection needs (characters per script,
trigram counts and, in `Mode::Enhanced`, word counts), so `feed` costs
time in proportion to the chunk and `detect` or `rank` in proportion to
the number of distinct trigrams seen:

```mbt check
///|
test {
  let chat = @mbglot.Accumulator::new()
  chat.feed("ok")
  assert_eq(chat.detect(), None)
  chat.feed("Hola, ¿cómo estás?")
  chat.feed("Muy bien, gracias. Tengo una pregunta sobre mi pedido.")
  assert_eq(chat.detect().map(d => d.lang), Some(@mbglot.Spa))
}
```

The result is that of `detect` on the chunks joined with line breaks
(a test checks this on cut-up benchmark texts in both modes), except on
long streams: franc looks only at the first 2048 UTF-16 code units of a
text, while an accumulator uses every chunk, so a long stream that
changes language follows the change. Markup is removed chunk by chunk.
`Detector::accumulator()` starts one with a detector's options, and
`reset` empties it.

## All of franc's languages

The `cn-nnzy/mbglot/full` package is franc 6.2.0 itself rather than
franc-min: 186 languages as franc counts them (once per script), 178
ISO 639-3 codes, including Catalan, Danish, Norwegian, Esperanto,
Hebrew, Georgian, Armenian and Khmer. Its languages are ISO 639-3 codes
(most have no `Lang`), and it offers franc's own functions, without the
passes of `Mode::Enhanced`:

```mbt check
///|
test {
  assert_eq(
    @full.franc("Bon dia, voldria saber quan arribarà la meva comanda."),
    "cat",
  )
  assert_eq(
    @full.franc(
      "שלום, ההזמנה שלי עדיין לא הגיעה. אפשר לבדוק?",
    ),
    "heb",
  )
  assert_eq(@full.franc_all("hi"), [("und", 1.0)])
  assert_eq(@full.languages().length(), 178)
}
```

It is a separate package so that applications that need only
franc-min's languages do not carry its 250 KB of data; import
`cn-nnzy/mbglot/full` in `moon.pkg` to use it. `tools/gen_full.mjs`
generates its data from the npm package and a golden test compares the
ten best entries and the number of entries of `francAll` with franc on
franc's fixtures in all 186 languages and on the hand-written cases, and
CI regenerates both. It uses the `Classifier` of
[Custom profiles](#custom-profiles) with franc's profiles.

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

### Benchmark

`moon run eval/run` evaluates mbglot on 5,541 sentences from
[Tatoeba](https://tatoeba.org) (CC BY 2.0 FR) in 72 of the 76 languages,
in three lengths: one sentence of 10 to 30 UTF-16 code units, one of 31 to
80, and several sentences joined to at least 150, with franc's ranking
alone (`Mode::Franc`) and with the default `Mode::Enhanced`.

The samples of each language and length alternate between a dev half and
a test half, in the corpus's SHA-256 order. Weights and thresholds are
chosen on the dev half, and the figures below are for the held-out test
half:

| Length | Mode | Samples | Accuracy | Group accuracy | Macro F1 | Reliable precision | Coverage |
|---|---|---:|---:|---:|---:|---:|---:|
| short | franc | 1027 | 64.8% | 70.2% | 63.0% | 92.6% | 2.6% |
| short | enhanced | 1027 | 71.3% | 76.7% | 69.7% | 97.1% | 36.4% |
| medium | franc | 911 | 80.2% | 85.7% | 80.2% | 96.5% | 62.8% |
| medium | enhanced | 911 | 85.6% | 90.5% | 85.8% | 98.4% | 67.3% |
| long | franc | 823 | 89.2% | 95.7% | 89.8% | 99.4% | 58.1% |
| long | enhanced | 823 | 94.2% | 98.2% | 95.0% | 99.2% | 77.0% |
| all | franc | 2761 | 77.2% | 82.9% | 73.8% | 97.7% | 39.0% |
| all | enhanced | 2761 | 82.8% | 87.6% | 79.4% | 98.4% | 58.7% |

Accuracy counts every detection. Group accuracy also counts as right a
language from the expected language's group: Bosnian, Croatian and
Serbian; Indonesian and Malay; Hindi, Bhojpuri, Maithili and Magahi;
Rundi and Kinyarwanda. These are standards of one language or dialect
continua that short written text often cannot separate, and they still
lead the confusions. Reliable precision is the share of detections
flagged `reliable` that are right, and coverage the share of samples that
get a reliable detection. [eval/results.md](eval/results.md) has the dev
half's figures, precision, recall and F1 for every language and the most
frequent confusions. CI reruns the benchmark and fails if
`eval/results.md` is out of date.

The split came after the short-text word weight and the word lists for
related languages were chosen on the whole corpus, so the enhanced
figures still profit from them somewhat; everything tuned since uses the
dev half only.

Tatoeba has no sentences in Chimborazo Highland Quichua (qug), Hmong
(hms), Yongbei Zhuang (zyb) and Magahi (mag), and fewer than 30 per
length in some other languages (for example 6 in Madurese, 4 in Hmong
Njua and 3 in Maithili; the per-language table gives each count), so
their figures are rough. The corpus is generated by
`tools/gen_tatoeba.py`; see [tools/README.md](tools/README.md).

### A second corpus: FLORES-200

Tatoeba sentences are short and conversational, and the word lists and
weights were chosen on them. To see whether the enhanced passes help on
other text, the benchmark also runs on
[FLORES-200](https://github.com/facebookresearch/flores) (CC BY-SA 4.0):
the same 40 devtest sentences, from English news and travel articles, in
the 68 of mbglot's languages it covers. Nothing was tuned on these
devtest sentences:

| Corpus | Mode | Samples | Accuracy | Group accuracy | Macro F1 | Reliable precision | Coverage |
|---|---|---:|---:|---:|---:|---:|---:|
| flores | franc | 2720 | 89.2% | 95.7% | 88.6% | 99.4% | 63.2% |
| flores | enhanced | 2720 | 92.0% | 97.5% | 91.7% | 99.4% | 73.1% |

Enhanced mode is right more often and makes 73.1% of detections reliable
instead of 63.2%, with the same reliable precision. Standard Malay is the
weak spot: 26 of its 40 sentences come out as Indonesian, against 18
with franc's ranking alone, because news Malay shares most of its words
with Indonesian and the near-tie rule then favours the larger language.
Group accuracy, which counts those as right, rises from 95.7% to 97.4%.
These figures showed the problem first; the fix (news words in the
Indonesian and Malay lists, and no prior for the Hindi belt) was then
chosen on the FLORES-200 dev set, a different set of sentences that is
not committed, and the Tatoeba dev half. `tools/gen_flores.py` generates
the corpus; Northern Pashto and Chimborazo Highland Quichua are missing because
FLORES-200 has Southern Pashto and Ayacucho Quechua instead.

### Speed

`moon run eval/speed --release --target <backend>` times `detect` over
the 5,541 benchmark texts with a `Detector`, and `segments` over 58 texts
of six sentences each, taking the best of five runs. On one Windows 11
laptop (Node.js 24 for `js`):

| Backend | `detect`, `Mode::Franc` | `detect`, `Mode::Enhanced` | `segments` |
|---|---:|---:|---:|
| wasm-gc | 66,800 texts/s | 31,500 texts/s | 935 texts/s |
| js | 36,900 texts/s | 17,200 texts/s | 518 texts/s |

Each text trigram is looked up once in an index of all the script's
profiles instead of once per language, and `segments` identifies each
stretch of text only once while it merges pieces. Before that, the same
machine managed 19,400 texts/s on wasm-gc and 15,700 on js in
`Mode::Franc`. `tools/bench_franc.mjs` times franc-min 6.2.0's
`francAll` on the same texts: 15,700 texts/s on the same Node.js, so
mbglot's JavaScript build is about 2.3 times as fast and its wasm-gc
build about 4 times, with identical rankings and scores on all 5,541
texts. Timings vary between machines and runs; the ratios are what
carries over.

## Development

```
moon update                # once: fetches the registry index for moonbitlang/x
moon fmt
moon info
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon test --target js      # needs Node.js
moon test --target native  # needs a C compiler
```

CI runs the same commands on Ubuntu 24.04, Windows Server 2025 and macOS
15 with a pinned MoonBit toolchain (moonc 0.10.17+093cb8f9c, set by
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

The `franc data` CI job runs these commands on every push and fails
if the result differs from the committed file.

## License

MIT, see [LICENSE](LICENSE). Data and algorithm come from franc-min
(MIT); the case tables come from the Unicode Character Database (Unicode
License V3). The benchmark corpora keep their own licenses:
`eval/tatoeba/corpus.mbt` is CC BY 2.0 FR (Tatoeba) and
`eval/flores/corpus.mbt` CC BY-SA 4.0 (FLORES-200). See
[NOTICE](NOTICE).
