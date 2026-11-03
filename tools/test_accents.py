#!/usr/bin/env python3
"""Characterization tests for the shared accent manifest."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from accents import accent_base, load


class AccentsTest(unittest.TestCase):
    def test_known_accents_are_loaded(self):
        accents, composed = load()

        self.assertEqual(accents["circumflex"], (0x005E, "above"))
        self.assertEqual(accents["cedilla"], (0x00B8, "below"))
        self.assertEqual(composed["circumflex"]["A"], 0x00C2)
        self.assertEqual(composed["circumflex"]["a"], 0x00E2)
        self.assertEqual(composed["cedilla"], {"C": 0x00C7, "c": 0x00E7})

    def test_accent_base_flattens_every_composed_character(self):
        _, composed = load()
        base = accent_base()

        self.assertEqual(len(base), sum(len(letters) for letters in composed.values()))
        self.assertEqual(base[0x00C2], (0x0041, "above"))
        self.assertEqual(base[0x00C7], (0x0043, "below"))
        self.assertEqual(base[0x00E2], (0x0061, "above"))
        self.assertEqual(base[0x00E7], (0x0063, "below"))


if __name__ == "__main__":
    unittest.main()
