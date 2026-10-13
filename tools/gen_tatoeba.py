"""Writes the Tatoeba benchmark corpus as a MoonBit file.

    python tools/gen_tatoeba.py CACHE_DIR eval/tatoeba/corpus.mbt

Downloads the per-language sentence exports of Tatoeba
(https://tatoeba.org, CC BY 2.0 FR) for mbglot's languages into CACHE_DIR,
unless they are already there, and picks for each language up to PER_BUCKET
texts of three lengths:

- short: one sentence of 10 to 30 UTF-16 code units;
- medium: one sentence of 31 to 80 code units;
- long: sentences of 20 to 120 code units joined with spaces until the text
  has at least 150 code units.

Sentences are taken in the order of SHA-256("<code>:<id>"), so the choice is
deterministic and does not depend on the export's row order; no sentence is
used twice. Each sample records the Tatoeba ids of its sentences for
attribution. A sentence that is removed from Tatoeba changes the selection
from then on, so the exports' Last-Modified date is written into the file.
"""

import bz2
import hashlib
import os
import sys
import urllib.request

BASE = "https://downloads.tatoeba.org/exports/per_language"
PER_BUCKET = 30

# mbglot language (franc-min ISO 639-3 code) -> Tatoeba codes. Tatoeba
# files Standard Arabic, North Azerbaijani, Northern Uzbek, Plateau
# Malagasy and Northern Pashto under the macrolanguage, and Malay under
# both zlm and zsm. Chimborazo Highland Quichua (qug), Hmong (hms), Yongbei
# Zhuang (zyb) and Magahi (mag) have no Tatoeba sentences in that variety
# and are left out.
TATOEBA = {
    "spa": ["spa"], "eng": ["eng"], "por": ["por"], "ind": ["ind"],
    "fra": ["fra"], "deu": ["deu"], "jav": ["jav"], "vie": ["vie"],
    "ita": ["ita"], "tur": ["tur"], "pol": ["pol"], "swh": ["swh"],
    "sun": ["sun"], "ron": ["ron"], "hau": ["hau"], "fuv": ["fuv"],
    "bos": ["bos"], "hrv": ["hrv"], "nld": ["nld"], "srp": ["srp"],
    "ckb": ["ckb"], "yor": ["yor"], "uzn": ["uzb"], "zlm": ["zlm", "zsm"],
    "ibo": ["ibo"], "ceb": ["ceb"], "tgl": ["tgl"], "hun": ["hun"],
    "azj": ["aze"], "ces": ["ces"], "run": ["run"], "plt": ["mlg"],
    "mad": ["mad"], "nya": ["nya"], "kin": ["kin"], "zul": ["zul"],
    "swe": ["swe"], "lin": ["lin"], "som": ["som"], "hnj": ["hnj"],
    "ilo": ["ilo"], "rus": ["rus"], "ukr": ["ukr"], "koi": ["koi"],
    "bel": ["bel"], "bul": ["bul"], "kaz": ["kaz"], "arb": ["ara"],
    "urd": ["urd"], "pes": ["pes"], "skr": ["skr"], "pbu": ["pus"],
    "hin": ["hin"], "mar": ["mar"], "mai": ["mai"], "bho": ["bho"],
    "npi": ["npi"], "cmn": ["cmn"], "ben": ["ben"], "jpn": ["jpn"],
    "kor": ["kor"], "tel": ["tel"], "tam": ["tam"], "guj": ["guj"],
    "kan": ["kan"], "mal": ["mal"], "mya": ["mya"], "pan": ["pan"],
    "amh": ["amh"], "tha": ["tha"], "sin": ["sin"], "ell": ["ell"],
}


def utf16_len(s):
    return len(s.encode("utf-16-le")) // 2


def download(cache, code):
    path = os.path.join(cache, f"{code}_sentences.tsv.bz2")
    if not os.path.exists(path):
        url = f"{BASE}/{code}/{code}_sentences.tsv.bz2"
        print(f"downloading {url}", file=sys.stderr)
        with urllib.request.urlopen(url) as resp, open(path + ".part", "wb") as f:
            f.write(resp.read())
        os.replace(path + ".part", path)
    return path


def last_modified(code):
    """Last-Modified of an export; all exports are published together."""
    req = urllib.request.Request(f"{BASE}/{code}/{code}_sentences.tsv.bz2", method="HEAD")
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.headers["Last-Modified"]
        except OSError:
            if attempt == 4:
                raise


def sentences(path, code):
    """(id, text) of every sentence in a per-language export."""
    out = []
    with bz2.open(path, "rt", encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 3 or parts[1] != code:
                continue
            text = " ".join(parts[2].split())
            if text:
                out.append((int(parts[0]), text))
    return out


def select(lang, rows):
    """Up to PER_BUCKET (bucket, ids, text) per bucket for one language."""
    keyed = sorted(rows, key=lambda r: hashlib.sha256(f"{r[2]}:{r[0]}".encode()).digest())
    seen_text = set()
    short, medium, pool = [], [], []
    for sid, text, _code in keyed:
        if text in seen_text:
            continue
        seen_text.add(text)
        n = utf16_len(text)
        if 10 <= n <= 30 and len(short) < PER_BUCKET:
            short.append(("Short", [sid], text))
        elif 31 <= n <= 80 and len(medium) < PER_BUCKET:
            medium.append(("Medium", [sid], text))
        elif 20 <= n <= 120:
            pool.append((sid, text))
    long = []
    ids, parts = [], []
    for sid, text in pool:
        if len(long) == PER_BUCKET:
            break
        ids.append(sid)
        parts.append(text)
        joined = " ".join(parts)
        if utf16_len(joined) >= 150:
            long.append(("Long", ids, joined))
            ids, parts = [], []
    return short + medium + long


def mbt_string(s):
    out = ['"']
    for ch in s:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ord(ch) < 0x20:
            out.append(f"\\u{{{ord(ch):x}}}")
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    cache, out_path = sys.argv[1], sys.argv[2]
    os.makedirs(cache, exist_ok=True)
    samples = []
    counts = []
    for lang, codes in TATOEBA.items():
        rows = []
        for code in codes:
            rows += [(sid, text, code) for sid, text in sentences(download(cache, code), code)]
        picked = select(lang, rows)
        counts.append((lang, picked))
        samples += [(lang, bucket, ids, text) for bucket, ids, text in picked]

    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("// Generated by tools/gen_tatoeba.py from Tatoeba. Do not edit.\n")
        f.write("// Sentences from Tatoeba (https://tatoeba.org), CC BY 2.0 FR.\n")
        f.write(f"// Exports dated {last_modified('eng')}.\n\n")
        # One table per language keeps each top-level item small enough for
        # the compiler.
        for lang, picked in counts:
            if not picked:
                continue
            enum = lang[0].upper() + lang[1:]
            f.write("///|\n")
            f.write(f"let rows_{lang} : Array[(@mbglot.Lang, Length, Array[Int], String)] = [\n")
            for bucket, ids, text in picked:
                id_list = ", ".join(str(i) for i in ids)
                f.write(f"  ({enum}, {bucket}, [{id_list}], {mbt_string(text)}),\n")
            f.write("]\n\n")
        f.write("///|\n")
        f.write("/// Every language's table, in mbglot's language order.\n")
        f.write("let tables : Array[Array[(@mbglot.Lang, Length, Array[Int], String)]] = [\n")
        for lang, picked in counts:
            if picked:
                f.write(f"  rows_{lang},\n")
        f.write("]\n")

    for lang, picked in counts:
        by_bucket = {b: sum(1 for p in picked if p[0] == b) for b in ("Short", "Medium", "Long")}
        if min(by_bucket.values()) < PER_BUCKET:
            print(f"{lang}: {by_bucket}", file=sys.stderr)
    print(f"{len(samples)} samples written to {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
