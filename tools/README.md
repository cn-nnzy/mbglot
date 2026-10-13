# tools

Generators for the data files in the package root. Their output is
committed.

## gen_profiles.mjs

Writes `profiles.mbt`: the trigram profiles of franc-min 6.2.0 and the key
order of its `expressions.js`. Needs Node.js. franc-min is installed into a
temporary directory and not committed; the script refuses any other
version.

```
npm install --prefix "$TMP/franc" --no-save --ignore-scripts franc-min@6.2.0
node tools/gen_profiles.mjs "$TMP/franc/node_modules/franc-min" profiles.mbt
moon fmt
```

The `franc-min data` job in CI runs exactly these commands and fails if
the result differs from the committed `profiles.mbt`.

## gen_golden.mjs

Writes `golden_wbtest.mbt`: franc-min 6.2.0 `francAll` results for franc's
test fixtures in supported languages and for the cases in
`golden_samples.json`. Needs Node.js. The fixtures file is downloaded from
a pinned commit and checked against its SHA-256.

```
npm install --prefix "$TMP/franc" --no-save --ignore-scripts franc-min@6.2.0
curl -fsSL -o "$TMP/fixtures.js" https://raw.githubusercontent.com/wooorm/franc/3f9f0b51a96c5df32a407dad865a3011ac0fa2d1/test/fixtures.js
node tools/gen_golden.mjs "$TMP/franc/node_modules/franc-min" "$TMP/fixtures.js" golden_wbtest.mbt
moon fmt
```

A sample in `golden_samples.json` has `name` and `text`, and optionally
`repeat` (repeat `text` that many times), `suffix`, `allow`, `deny` and
`minLength`. The `franc-min data` CI job regenerates this file too, and
uploads the regenerated files as an artifact when they differ.

## unicode_case.py

Writes `unicode_case.mbt`: simple lowercase mappings and the `Cased` and
`Case_Ignorable` properties from the Unicode Character Database, which
`trigram.mbt` uses to reproduce JavaScript's `toLowerCase`. Needs Python 3
and network access; uses only the standard library.

```
python tools/unicode_case.py unicode_case.mbt
moon fmt
```

The Unicode version is pinned in the script (`UNICODE_VERSION`). The script
stops if that version adds an unconditional full lowercase mapping other
than U+0130, which `trigram.mbt` handles by hand.

## loc.py

Counts lines of MoonBit by kind and prints a table. Needs Python 3; uses
only the standard library. `-v` lists every file.

```
python tools/loc.py
```

Files whose first line says `Do not edit` (written by the generators
above) and `script_ranges.mbt` (transcribed from franc-min) count as
generated; `*_test.mbt` and `*_wbtest.mbt` as tests; the `cmd`,
`examples`, `demo` and `eval/run` packages as apps; everything else as
core library code. Non-blank lines and code lines (non-blank lines that
are not only a comment) are counted separately.
