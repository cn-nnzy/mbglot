# mbglot

Offline language identification for [MoonBit](https://www.moonbitlang.com),
ported from [franc-min](https://github.com/wooorm/franc/tree/main/packages/franc-min)
6.2.0. No network access, no native dependencies; the same results on the
wasm, wasm-gc, js and native backends.

## Status

mbglot is under construction. This section lists what exists today and
what is planned, and is updated with every change.

Implemented now:

- `Lang`: the 76 languages of franc-min 6.2.0, with `code()` (ISO 639-3),
  `name()` (English), `Lang::from_code` and `Lang::all()`.
- `Script`: the 20 writing systems franc-min distinguishes, with `name()`
  and `Script::all()`.
- `detect_script(text) -> Script?`: the writing system used by most
  characters, with franc-min's Unicode ranges, sample limit (first 2048
  UTF-16 code units) and tie order. Returns `None` for text with no
  letters of a supported script (empty, digits, punctuation, emoji).

Planned, not implemented yet:

- Trigram profiles generated from franc-min 6.2.0, and trigram extraction
  matching `trigram-utils`.
- `detect(text, options?)` and `rank(text, options?)` with `Options`
  (allow / deny lists, minimum length) and a `reliable` flag, checked
  against franc-min with a parity test.
- A command-line tool in `cmd/main` and examples.

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

CI runs the same commands on Ubuntu, Windows and macOS.

## License

MIT, see [LICENSE](LICENSE). Data and algorithm come from franc-min
(MIT); see [NOTICE](NOTICE).
