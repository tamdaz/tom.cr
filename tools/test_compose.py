#!/usr/bin/env python3
"""Characterization tests for composing accents onto lowercase glyphs."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from compose_accents import compose

LETTER = ["          ", "          "] + ["██      ██"] * 5


class ComposeTest(unittest.TestCase):
    def test_lowercase_accent_fills_the_blank_rows(self):
        rows = compose(LETTER, "circumflex", lowercase=True)

        self.assertEqual(len(rows), 7)
        self.assertNotEqual(rows[:2], LETTER[:2])
        self.assertEqual(rows[2:], LETTER[2:])

    def test_lowercase_cedilla_hangs_below_the_letter(self):
        rows = compose(LETTER, "cedilla", lowercase=True)

        self.assertEqual(len(rows), 9)
        self.assertEqual(rows[:7], LETTER)

    def test_uppercase_accent_adds_two_rows_above(self):
        rows = compose(["██      ██"] * 7, "circumflex")

        self.assertEqual(len(rows), 9)
        self.assertEqual(rows[2:], ["██      ██"] * 7)


if __name__ == "__main__":
    unittest.main()
