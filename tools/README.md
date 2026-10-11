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
