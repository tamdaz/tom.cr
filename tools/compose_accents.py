#!/usr/bin/env python3
"""Compose accented glyphs from the accent art and the base letter variants.

Accented uppercase glyphs are 10x9: the base letter keeps its original 10x7
grid, and two rows are added for the accent. Accents above the letter use the
first two rows of ASCII 94 (`^`), ASCII 96 (`` ` ``), U+00B4 (`´`) or U+00A8
(`¨`); the cedilla uses the last two rows of U+00B8 (`¸`) and sits below the
letter.

Lowercase art keeps at most two rows above the x-height — blank, or the dot on
`i` — and accents fill that zone instead of making the glyph taller, so an
accented lowercase stays 10x7. The lowercase cedilla still appends its two rows
below.

Every variant of a base letter produces the matching variant of its accented
form (A variant 2 -> Â variant 2), so accents follow the letter designs. A
variant already stored without an extra accent (7 rows) keeps that design, even
if its top rows happen to resemble the requested accent; otherwise the new
accent is added above the complete variant. Some letter designs start with rows
that look like an accent (A3, O2), but those rows belong to the letter unless
the stored variant deliberately reuses them. The results are written to
`src/data/<codepoint>/<variant>.txt`, next to the hand-drawn glyph art.
"""
import glob
import os
import sys

from accents import load

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "src", "data")

COLS, HALF_ROWS = 10, 7
BLOCK, TOP, BOTTOM = "█", "▀", "▄"

# Accent name -> (accent codepoint, side), and accent name -> {base: composed}.
ACCENTS, COMPOSED = load()


def read_rows(path):
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().rstrip("\n").split("\n")
    if len(lines) != HALF_ROWS or any(len(line) != COLS for line in lines):
        raise SystemExit(f"{path}: expected a {COLS}x{HALF_ROWS} grid")
    return lines


def letter_variants(letter):
    """Return {variant number: rows} for every design of *letter*."""
    paths = glob.glob(os.path.join(DATA, str(ord(letter)), "*.txt"))
    variants = {}
    for path in sorted(paths):
        number = int(os.path.splitext(os.path.basename(path))[0])
        variants[number] = read_rows(path)
    if not variants:
        raise SystemExit(f"{letter}: no glyph variants found")
    return variants


def accent_rows(name):
    """Return the two accent rows, rejecting art with stray marks elsewhere."""
    code, side = ACCENTS[name]
    path = os.path.join(DATA, str(code), "1.txt")
    rows = read_rows(path)
    if side == "above":
        used, unused = rows[:2], rows[2:]
    else:
        used, unused = rows[-2:], rows[:-2]

    if any(char != " " for row in unused for char in row):
        raise SystemExit(f"{chr(code)}: accent must use the top/bottom two rows only")
    if not any(char != " " for row in used for char in row):
        raise SystemExit(f"{chr(code)}: accent rows are empty")
    return used


def existing_above_accent(letter_rows):
    """Return the accent name already present in the letter's top rows, if any."""
    top = letter_rows[:2]
    for name, (_, side) in ACCENTS.items():
        if side == "above" and top == accent_rows(name):
            return name
    return None


def read_target(path):
    """Return the rows already stored for an accented glyph, if any."""
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as handle:
        return handle.read().rstrip("\n").split("\n")


def compose(letter_rows, name, current_rows=None, lowercase=False):
    """Add *name*, keeping a deliberately reused accent and never cutting the letter."""
    _, side = ACCENTS[name]
    accent = accent_rows(name)

    if side == "above" and lowercase:
        # Lowercase art keeps at most two rows above the x-height (blank, or the
        # dot on i). Put the accent there instead of stacking it on top.
        rows = accent + letter_rows[2:]
    elif side == "above":
        already_reused = (current_rows == letter_rows
                          and existing_above_accent(letter_rows) == name)
        if already_reused:
            return letter_rows
        rows = accent + letter_rows
    else:
        rows = letter_rows + accent

    expected = HALF_ROWS if side == "above" and lowercase else HALF_ROWS + 2
    if len(rows) != expected:
        raise SystemExit(f"composed {len(rows)} rows, expected {expected}")
    return rows


def write(code, variants):
    directory = os.path.join(DATA, str(code))
    os.makedirs(directory, exist_ok=True)
    for number, rows in sorted(variants.items()):
        path = os.path.join(directory, f"{number}.txt")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("\n".join(rows) + "\n")
        print(f"U+{code:04X} {chr(code)} variant {number}: {os.path.relpath(path, ROOT)}")


def main():
    for name, letters in COMPOSED.items():
        for letter, code in letters.items():
            variants = {}
            for number, rows in letter_variants(letter).items():
                path = os.path.join(DATA, str(code), f"{number}.txt")
                variants[number] = compose(
                    rows, name, read_target(path), lowercase=letter.islower())
            write(code, variants)
    return 0


if __name__ == "__main__":
    sys.exit(main())
