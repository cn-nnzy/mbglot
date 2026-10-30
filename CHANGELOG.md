# Changelog

All notable changes to mbglot. Accuracy figures are from
[eval/results.md](eval/results.md) on the held-out halves of the
benchmarks.

## Unreleased

- Faster: `detect` in `Mode::Enhanced` about twice as fast (66,800 texts/s
  on wasm-gc instead of 31,500), `Mode::Franc` about 1.8 times and
  `segments` about 2.2 times. Results are unchanged, except that the
  Cebuano word `kaayo`, listed twice, now counts once.
- The demo compares mbglot with franc-min's trigrams alone.
- Ukrainian is no longer taken for Belarusian when it lacks ї, є and ґ.
- CI checks that the module packages for mooncakes.io.

## 0.1.0 (2026-10-30)

The first release.

### Detection

- `detect`, `rank` and `Options` (allow and deny lists, minimum length,
  mode, markup removal). In `Mode::Franc` the rankings and scores equal
  franc-min 6.2.0's, checked by a golden test on franc's fixtures.
- `Mode::Enhanced`, the default, adds to franc's ranking:
  - removal of URLs, e-mail addresses, mentions, hashtags, HTML and code,
    with a map back to the original offsets;
  - Chinese, Japanese and Korean settled by their shares of kana, Han
    and Hangul, and `chinese_variant` for simplified or traditional
    characters;
  - common words for short texts;
  - letters and words that settle related languages, in groups per
    script: Spanish and Portuguese; the Cyrillic languages; Bosnian,
    Croatian and Serbian; Indonesian and Malay; Rundi and Kinyarwanda;
    Tagalog and Cebuano; Hausa and Nigerian Fulfulde; Javanese and
    Sundanese; the Arabic-script languages;
  - near ties within a group broken toward the language with more
    speakers.
- `Detection` with `margin`, `runner_up`, a `confidence` that counts the
  deciding letters and words, and a `reliable` flag.
- `Detector` for many texts with the same options, with trigrams looked
  up once per text in an index of all profiles: about 2.3 times as fast
  as franc-min on the same Node.js, with identical results.
- `segments` for text that mixes languages, `detect_script`,
  `explain` for the steps and trigrams behind a decision, and
  `Accumulator` for text that arrives in chunks.
- `Profile::train`, `Profile::save` and `Profile::parse`, and a
  `Classifier` that compares any mix of trained and built-in profiles.
- `Lang` with ISO 639-3 and 639-1 codes, BCP 47 tags (`Lang::from_bcp47`
  reads `pt-BR` or `zh-Hant-TW`), English and native names and speaker
  counts.
- The `full` package: franc 6.2.0 with all 186 of its languages.

### Tools

- A command-line tool with JSON output, `--explain`, `--segments`,
  language options and a mode for files of one text per line.
- A browser demo, published with GitHub Pages.
- A ticket-routing example.

### Evaluation

- The `eval` package: accuracy, confusion counts and per-language
  precision, recall and F1 for any predictor.
- Benchmarks on Tatoeba (72 languages, split into dev and test halves)
  and FLORES-200 devtest (68 languages, out of domain). On the held-out
  sets mbglot is 83.1% accurate on Tatoeba and 92.5% on FLORES-200,
  against 77.2% and 89.2% for franc-min's ranking alone; CI regenerates
  the results and checks that the README quotes them.
