# tools

Generators for the data files in the package root. Their output is
committed; CI does not run them.

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
