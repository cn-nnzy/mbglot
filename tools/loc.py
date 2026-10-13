"""Counts lines of MoonBit in this repository by kind.

    python tools/loc.py

Every .mbt file outside _build and .mooncakes is put in one group:

- generated: files whose first line says "Do not edit" (written by the
  scripts in tools/) and the data tables listed in DATA_FILES;
- tests: *_test.mbt and *_wbtest.mbt that are not generated;
- core: the remaining files of library packages;
- apps: the remaining files of executable and demo packages (APP_DIRS).

Lines are counted twice: all non-blank lines, and code lines, which also
leave out lines that are only a comment.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {"_build", ".mooncakes", "node_modules", ".git", "_site"}

# Data transcribed from franc-min rather than written: counted as generated.
DATA_FILES = {"script_ranges.mbt"}

# Packages that are programs or demos built on the library, not library code.
APP_DIRS = ("cmd/", "examples/", "demo/", "eval/run/")

GROUPS = ("core", "apps", "tests", "generated")


def classify(rel, first_line):
    name = os.path.basename(rel)
    if "Do not edit" in first_line or name in DATA_FILES:
        return "generated"
    if name.endswith("_test.mbt") or name.endswith("_wbtest.mbt"):
        return "tests"
    if rel.startswith(APP_DIRS):
        return "apps"
    return "core"


def count(path):
    nonblank = code = 0
    with open(path, encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if not stripped:
                continue
            nonblank += 1
            if not stripped.startswith("//"):
                code += 1
    return nonblank, code


def main():
    per_group = {g: [0, 0, 0] for g in GROUPS}  # files, non-blank, code
    per_file = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        for name in sorted(filenames):
            if not name.endswith(".mbt"):
                continue
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            with open(path, encoding="utf-8") as f:
                first_line = f.readline()
            group = classify(rel, first_line)
            nonblank, code = count(path)
            totals = per_group[group]
            totals[0] += 1
            totals[1] += nonblank
            totals[2] += code
            per_file.append((group, rel, nonblank, code))

    if "-v" in sys.argv[1:]:
        for group, rel, nonblank, code in sorted(per_file):
            print(f"{group:<10} {nonblank:>6} {code:>6}  {rel}")
        print()
    print(f"{'group':<10} {'files':>5} {'non-blank':>10} {'code':>6}")
    for group in GROUPS:
        files, nonblank, code = per_group[group]
        print(f"{group:<10} {files:>5} {nonblank:>10} {code:>6}")


if __name__ == "__main__":
    main()
