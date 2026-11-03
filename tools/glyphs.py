#!/usr/bin/env python3
"""Shared geometry for the half-block glyph art in ``src/data``.

The constants and parsing here are deliberately free of FontForge and
fontTools imports so that the glyph format can be tested without the optional
font-building dependencies installed.
"""
import os

from accents import accent_base

COLS, HALF_ROWS = 10, 7
ROWS = HALF_ROWS * 2       # a text row is two pixel rows
MAX_EXTRA_HALF_ROWS = 4    # allow 10x11 grids, enough for a deeper descender

# Accented codepoint -> (base letter, side of the accent), from the shared
# accent manifest. The accented variants belong to the base letter's cv
# feature, so selecting "A Variants" also updates all A accents and their
# lowercase forms. The side tells the outline builder whether the extra two
# rows go above the letter or below it (the cedilla).
ACCENT_BASE = accent_base()

# The cedilla is an accent like the others, but it sits below the letter.
BELOW_BASELINE = {code for code, (_, side) in ACCENT_BASE.items() if side == "below"}

# Lowercase letters whose tail hangs under the baseline. Most of them can also
# be recognised by their blank leading rows, but j keeps its dot up there and
# must be listed explicitly. Keep in sync with DESCENDERS in src/normal.cr.
DESCENDERS = {ord(letter) for letter in "gjpqy"}

BLOCK, BLOCK_TOP, BLOCK_BOTTOM = "█", "▀", "▄"


def parse(path):
    """Return a matrix of 0/1 from one half-block art file.

    Glyphs are at least 10x7. Extra rows are used for accents above the letter
    or for parts that hang below the baseline (the cedilla, descenders).
    """
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().rstrip("\n").split("\n")

    max_rows = HALF_ROWS + MAX_EXTRA_HALF_ROWS

    if not HALF_ROWS <= len(lines) <= max_rows or any(len(line) != COLS for line in lines):
        raise SystemExit(f"{path}: expected a {COLS}x{HALF_ROWS} to {COLS}x{max_rows} grid")

    grid = [[0] * COLS for _ in range(len(lines) * 2)]

    for r, line in enumerate(lines):
        for c, char in enumerate(line):
            if char in (BLOCK, BLOCK_TOP):
                grid[r * 2][c] = 1
            if char in (BLOCK, BLOCK_BOTTOM):
                grid[r * 2 + 1][c] = 1
    return grid


def delegated_lowercase(code, glyphs):
    """Return the lowercase codepoint that shares *code*'s design, if any.

    A lowercase letter with its own art keeps that design and gets its own cv
    feature. Only lowercase forms the builder synthesises from the capital --
    the accented letters, which have no art of their own -- should follow the
    capital's variants.
    """
    lower = chr(code).lower()

    if len(lower) != 1 or lower == chr(code):
        return None

    lower_code = ord(lower)
    return None if lower_code in glyphs else lower_code


def hangs_below(code, grid):
    """Return whether *grid* has ink under the shared baseline.

    The cedilla and the lowercase descenders are below by definition. As a
    fallback, a taller glyph with blank leading x-height rows is also a
    descender: accented letters use those rows for the accent itself.
    """
    if code in BELOW_BASELINE or code in DESCENDERS:
        return True

    return len(grid) > ROWS and not any(any(row) for row in grid[:4])
