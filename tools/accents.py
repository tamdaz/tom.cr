#!/usr/bin/env python3
"""Shared accent metadata, read from ``src/data/accents.tsv``.

``src/normal.cr`` reads the same manifest at compile time, so the renderer and
the font-building scripts cannot drift apart. Each row is:

    accent  side  accent_code  base_code  composed_code

where the codes are decimal Unicode code points and *side* is ``above`` or
``below``.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "src", "data", "accents.tsv")


def rows():
    """Yield the manifest records in file order."""
    with open(PATH, encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            accent, side, accent_code, base_code, composed_code = line.split("\t")
            yield accent, side, int(accent_code), int(base_code), int(composed_code)


def load():
    """Return ``(ACCENTS, COMPOSED)`` in the order they appear in the file.

    ``ACCENTS`` maps an accent name to ``(codepoint, side)``; ``COMPOSED`` maps
    an accent name to ``{base character: composed codepoint}``.
    """
    accents = {}
    composed = {}
    for accent, side, accent_code, base_code, composed_code in rows():
        accents.setdefault(accent, (accent_code, side))
        composed.setdefault(accent, {})[chr(base_code)] = composed_code
    return accents, composed


def accent_base():
    """Return ``{composed codepoint: (base codepoint, side)}`` for the TTF."""
    return {
        composed_code: (base_code, side)
        for _, side, _, base_code, composed_code in sorted(rows(), key=lambda row: row[4])
    }
