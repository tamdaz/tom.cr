#!/usr/bin/env python3
"""Characterization tests for the half-block glyph format and baseline."""
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from glyphs import ROWS, delegated_lowercase, hangs_below, parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "src", "data")


def glyph(code):
    return parse(os.path.join(DATA, str(code), "1.txt"))


class GlyphsTest(unittest.TestCase):
    def test_descender_hangs_below_the_baseline(self):
        grid = glyph(ord("p"))

        self.assertEqual(len(grid), ROWS + 4)
        self.assertTrue(hangs_below(ord("p"), grid))

    def test_dotted_descender_hangs_below_the_baseline(self):
        grid = glyph(ord("j"))

        self.assertEqual(len(grid), ROWS + 4)
        self.assertTrue(hangs_below(ord("j"), grid))

    def test_accent_stays_above_the_baseline(self):
        grid = glyph(0x00C2)  # Â

        self.assertEqual(len(grid), ROWS + 4)
        self.assertFalse(hangs_below(0x00C2, grid))

    def test_cedilla_hangs_below_the_baseline(self):
        grid = glyph(0x00C7)  # Ç

        self.assertTrue(hangs_below(0x00C7, grid))

    def test_capital_has_no_descender(self):
        self.assertFalse(hangs_below(ord("P"), glyph(ord("P"))))

    def test_accepts_a_deeper_ten_by_eleven_descender(self):
        rows = ["          "] * 2 + ["██        "] * 9

        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".txt") as handle:
            handle.write("\n".join(rows) + "\n")
            handle.flush()
            grid = parse(handle.name)

        self.assertEqual(len(grid), 22)
        self.assertTrue(hangs_below(ord("p"), grid))

    def test_lowercase_with_its_own_art_does_not_follow_the_capital(self):
        glyphs = {ord("A"): {1: []}, ord("a"): {1: []}}

        self.assertIsNone(delegated_lowercase(ord("A"), glyphs))

    def test_synthesised_accented_lowercase_follows_the_capital(self):
        glyphs = {0x00C2: {1: []}}

        self.assertEqual(delegated_lowercase(0x00C2, glyphs), 0x00E2)

    def test_rejects_grids_taller_than_ten_by_eleven(self):
        rows = ["          "] * 12

        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".txt") as handle:
            handle.write("\n".join(rows) + "\n")
            handle.flush()
            with self.assertRaises(SystemExit):
                parse(handle.name)


if __name__ == "__main__":
    unittest.main()
