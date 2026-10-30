"""Checks that the README quotes eval/results.md correctly.

    python tools/readme_tables.py           # exit status 1 if not
    python tools/readme_tables.py --write   # update README.mbt.md

The README copies three tables of eval/results.md (the Tatoeba test half,
FLORES-200 and custom profiles) and summarises them in the table under
"At a glance". CI regenerates eval/results.md and fails if it changed;
this script makes the README fail the same way, instead of going stale.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
README = os.path.join(ROOT, "README.mbt.md")
RESULTS = os.path.join(ROOT, "eval", "results.md")

# Header lines of the tables copied verbatim; the first match in each file.
COPIED = (
    "| Length | Mode | Samples | Accuracy | Group accuracy",
    "| Corpus | Mode |",
    "| Profiles |",
)
GLANCE = "| Held-out benchmark |"


def table_at(text, header):
    """(start, end) of the table whose first line starts with header."""
    start = text.index(header)
    end = text.find("\n\n", start)
    return start, (len(text) if end < 0 else end)


def row(text, header, label):
    """The cells of the row starting with label in the table of header."""
    start, end = table_at(text, header)
    for line in text[start:end].split("\n"):
        if line.startswith(label):
            return [cell.strip() for cell in line.strip("|").split("|")]
    raise SystemExit(f"no row {label!r} under {header!r}")


def glance(results):
    """The "At a glance" table, built from eval/results.md."""
    tatoeba = COPIED[0]
    franc = row(results, tatoeba, "| all | franc |")
    enhanced = row(results, tatoeba, "| all | enhanced |")
    flores_franc = row(results, COPIED[1], "| flores | franc |")
    flores_enhanced = row(results, COPIED[1], "| flores | enhanced |")
    count = lambda n: f"{int(n):,}"
    return "\n".join([
        "| Held-out benchmark | franc-min's ranking | mbglot (default) |",
        "|---|---:|---:|",
        f"| Accuracy, Tatoeba test half ({count(franc[2])} texts) | {franc[3]} | {enhanced[3]} |",
        f"| Accuracy, FLORES-200 devtest ({count(flores_franc[2])} texts) | {flores_franc[3]} | {flores_enhanced[3]} |",
        f"| Answered as `reliable`, Tatoeba test half | {franc[7]} | {enhanced[7]} |",
    ])


def main():
    results = open(RESULTS, encoding="utf-8").read()
    readme = open(README, encoding="utf-8").read()
    expected = readme
    for header in COPIED:
        a, b = table_at(results, header)
        c, d = table_at(expected, header)
        expected = expected[:c] + results[a:b].rstrip("\n") + expected[d:]
    c, d = table_at(expected, GLANCE)
    expected = expected[:c] + glance(results) + expected[d:]
    if expected == readme:
        print("README tables match eval/results.md")
        return
    if "--write" in sys.argv[1:]:
        with open(README, "w", encoding="utf-8", newline="\n") as f:
            f.write(expected)
        print("README tables updated")
        return
    sys.exit("README tables differ from eval/results.md; run python tools/readme_tables.py --write")


if __name__ == "__main__":
    main()
