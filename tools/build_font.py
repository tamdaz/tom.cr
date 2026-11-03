#!/usr/bin/env python3
"""Build an outline TTF from the half-block glyph art in src/data.

A glyph is a 10x7 grid of ▀ / ▄ / █ cells, i.e. a 10x14 bitmap. Extra rows
grow the grid: accented capitals use 10x9 (two rows added above an unchanged
10x7 letter, or below for the cedilla). Lowercase letters keep the two rows
above the x-height free for the accent (blank, or the dot on i), so an accented
lowercase stays 10x7; only the lowercase cedilla adds rows below. Descenders
such as p use the rows under the baseline for their tail. The bitmap
is emitted as one rectangle per horizontal run, then the rectangles are merged,
so the outlines are exact pixel edges: no autotracing, no wobble.

Alternate designs (2.txt, 3.txt, ...) become unencoded glyphs wired to a cvXX
character-variant feature per character, so they can be picked in any
OpenType-aware application.
"""
import argparse
import glob
import os
import sys

import fontforge
from fontTools.feaLib.builder import addOpenTypeFeaturesFromString
from fontTools.ttLib import TTFont

from glyphs import ACCENT_BASE, COLS, ROWS, delegated_lowercase, hangs_below, parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PX = 100                   # font units per bitmap pixel
UPM = ROWS * PX            # 1400
ADVANCE = (COLS + 2) * PX  # 10px glyph + 2px letter spacing


def draw(glyph, grid, code):
    """Add one rectangle per horizontal run of set pixels.

    Row 0 is the top row. The bottom of the 10x7 body sits on the baseline
    (y=0). For below-baseline glyphs the baseline is fixed at the bottom of the
    seventh text row, so rows past it extend into negative coordinates.
    """

    rows = len(grid)
    below = hangs_below(code, grid)
    baseline = rows - 1 - (rows - ROWS if below else 0)
    pen = glyph.glyphPen()

    for y, row in enumerate(grid):
        x = 0

        while x < COLS:
            if not row[x]:
                x += 1
                continue

            x0 = x

            while x < COLS and row[x]:
                x += 1

            y0 = (baseline - y) * PX
            pen.moveTo((x0 * PX, y0))
            pen.lineTo((x0 * PX, y0 + PX))
            pen.lineTo((x * PX, y0 + PX))
            pen.lineTo((x * PX, y0))
            pen.closePath()
    pen = None


def collect(data):
    """Return {codepoint: {variant number: grid}} from src/data."""
    glyphs = {}

    for directory in glob.glob(os.path.join(data, "*")):
        code = os.path.basename(directory)

        if not code.isdigit():
            continue

        for path in glob.glob(os.path.join(directory, "*.txt")):
            number = int(os.path.splitext(os.path.basename(path))[0])
            glyphs.setdefault(int(code), {})[number] = parse(path)

    return glyphs


def vertical_metrics(glyphs):
    """Return the ascent/descent (in font units) that every design needs."""
    above = below = 0

    for code, designs in glyphs.items():
        for grid in designs.values():
            extra = max(0, len(grid) - ROWS)
            if hangs_below(code, grid):
                below = max(below, extra)
            else:
                above = max(above, extra)

    return UPM + above * PX, below * PX


def build(data, out, family, lowercase):
    font = new_font(family)
    glyphs = collect(data)
    names = add_default_glyphs(font, glyphs)

    if lowercase:
        add_lowercase_glyphs(font, glyphs, names)

    alternates = add_alternates(font, glyphs, names)
    features = collect_features(alternates)

    ascent, descent = vertical_metrics(glyphs)

    clean_outlines(font)
    generate_font(font, out, features)
    tt = normalize_metrics(out, ascent, descent)

    return len(tt.getBestCmap()), len(features)


def new_font(family):
    """Create the FontForge font with the shared global metrics."""
    font = fontforge.font()
    font.em = UPM
    font.ascent = UPM
    font.descent = 0

    font.familyname = family
    font.fullname = f"{family} Regular"
    font.fontname = family.replace(" ", "") + "-Regular"
    font.version = "0.1.0"
    font.copyright = "Copyright (c) tamdaz. MIT licensed."

    for attr in ("hhea_ascent", "hhea_descent", "os2_typoascent",
                 "os2_typodescent", "os2_winascent", "os2_windescent"):
        setattr(font, attr + "_add", 0)

    font.hhea_ascent = UPM
    font.hhea_descent = 0
    font.hhea_linegap = 0
    font.os2_typoascent = UPM
    font.os2_typodescent = 0
    font.os2_typolinegap = 0
    font.os2_winascent = UPM
    font.os2_windescent = 0
    font.os2_capheight = UPM
    font.os2_xheight = UPM
    font.os2_use_typo_metrics = 1
    font.os2_panose = (2, 0, 5, 9, 0, 0, 0, 0, 0, 0)

    # U+0020 is absent from the art but the renderer gives it a full cell.
    font.createChar(0x20).width = ADVANCE

    return font


def add_default_glyphs(font, glyphs):
    """Draw variant 1 of every glyph and return {codepoint: glyph name}."""
    names = {}  # codepoint -> default glyph name

    for code, designs in sorted(glyphs.items()):
        if 1 not in designs:
            continue

        glyph = font.createChar(code)
        draw(glyph, designs[1], code)
        glyph.width = ADVANCE
        names[code] = glyph.glyphname

    return names


def add_lowercase_glyphs(font, glyphs, names):
    """Repeat the capitals as lowercase glyphs, mutating *names*.

    The renderer upcases its input, so lowercase only needs to exist for
    applications using the generated TTF directly. This covers ASCII and the
    accented Latin-1 letters (Â -> â, etc.).
    """
    for code, _name in list(names.items()):
        lower = chr(code).lower()
        if len(lower) != 1 or lower == chr(code):
            continue
        lower_code = ord(lower)
        if lower_code in names:
            continue
        glyph = font.createChar(lower_code)
        draw(glyph, glyphs[code][1], code)
        glyph.width = ADVANCE
        names[lower_code] = glyph.glyphname


def add_alternates(font, glyphs, names):
    """Create the unencoded alternate designs and return their metadata.

    One cvXX feature per character holds all of its alternate designs (variant
    2, 3, 4, ...). The alternates are unencoded glyphs with predictable names
    so the feature file can reference them.
    """
    alternates = {}  # codepoint -> (default glyph names, {variant: alternate name})

    for code, designs in sorted(glyphs.items()):
        if code not in names:
            continue

        extra = [number for number in sorted(designs) if number != 1]

        if not extra:
            continue
        variants = {}
        for number in extra:
            alternate = font.createChar(-1, f"{names[code]}.alt{number}")
            draw(alternate, designs[number], code)
            alternate.width = ADVANCE
            variants[number] = alternate.glyphname
        # Lowercase letters with their own art get their own cv feature; only
        # the accented lowercase forms, which are copied from the capital,
        # follow the capital's variants.
        bases = [names[code]]
        lower_code = delegated_lowercase(code, glyphs)
        if lower_code is not None and lower_code in names:
            bases.append(names[lower_code])
        alternates[code] = (bases, variants)

    return alternates


def collect_features(alternates):
    """Group the accented characters into their base letter's feature.

    The variant numbers must line up so value 1 of "A Variants" picks Â's first
    alternate as well as A's.
    """
    features = {}  # base codepoint -> {glyph name: [alternate names, by variant]}

    for code, (bases, variants) in alternates.items():
        base = ACCENT_BASE.get(code, (code, "above"))[0]
        if base not in alternates:
            continue
        order = sorted(alternates[base][1])
        if sorted(variants) != order:
            if code != base:
                raise SystemExit(
                    f"{chr(code)} variants {sorted(variants)} do not match "
                    f"{chr(base)} variants {order}")
            continue
        slot = features.setdefault(base, {})
        for name in bases:
            slot[name] = [variants[number] for number in order]

    return features


def clean_outlines(font):
    """Merge overlapping rectangles and normalise contour direction."""
    font.selection.all()
    font.removeOverlap()
    font.correctDirection()


def generate_font(font, out, features):
    """Generate the TTF, add its cvXX features, and save it."""
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    font.generate(out)

    tt = TTFont(out)
    add_character_variants(tt, features)
    tt.save(out)


def normalize_metrics(out, ascent, descent):
    """Normalise synthesised glyph widths and line metrics, then save."""
    # FontForge only synthesises .notdef/.null/nonmarkingreturn on export;
    # normalise them so the font is reported as fixed pitch.
    tt = TTFont(out)
    for name, width in ((".notdef", ADVANCE), (".null", 0), ("nonmarkingreturn", 0)):
        tt["hmtx"][name] = (width, 0)
    tt["hhea"].advanceWidthMax = ADVANCE
    tt["post"].isFixedPitch = 1

    # Keep the em (and so the pixel size) at UPM, but grow the line box so
    # accents and descenders are not clipped. FontForge cannot express an
    # ascent above the em, so these metrics are written after generation.
    tt["hhea"].ascent = ascent
    tt["hhea"].descent = -descent
    tt["hhea"].lineGap = 0
    tt["OS/2"].sTypoAscender = ascent
    tt["OS/2"].sTypoDescender = -descent
    tt["OS/2"].sTypoLineGap = 0
    tt["OS/2"].usWinAscent = ascent
    tt["OS/2"].usWinDescent = descent
    tt.save(out)

    return tt


def add_character_variants(tt, features):
    """Wire each character's alternates into its own cvXX feature.

    *features* maps a base codepoint to {glyph name: [alternates by variant]}.
    Accented characters share their base letter's feature, so one value updates
    both the plain and accented glyphs.
    """
    if not features:
        return
    blocks = []
    for index, code in enumerate(sorted(features), start=1):
        character = chr(code)
        accented = "".join(chr(accent) for accent in sorted(ACCENT_BASE)
                           if ACCENT_BASE[accent][0] == code)
        rules = "\n".join(f"    sub {base} from [{' '.join(alts)}];"
                          for base, alts in features[code].items())
        blocks.append(
            f"feature cv{index:02d} {{\n"
            f"    cvParameters {{\n"
            f"        FeatUILabelNameID {{ name \"{character} Variants\"; }};\n"
            f"        SampleTextNameID {{ name \"{character}{accented}\"; }};\n"
            f"        Character 0x{code:04X};\n"
            f"    }};\n"
            f"{rules}\n"
            f"}} cv{index:02d};\n"
        )
    addOpenTypeFeaturesFromString(tt, "\n".join(blocks))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", default=os.path.join(ROOT, "src", "data"))
    parser.add_argument("--out", default=os.path.join(ROOT, "dist", "TomMono-Regular.ttf"))
    parser.add_argument("--family", default="Tom Mono")
    parser.add_argument("--no-lowercase", action="store_true",
                        help="do not map a-z to the capital glyphs")
    args = parser.parse_args()

    count, variants = build(args.data, args.out, args.family, not args.no_lowercase)
    suffix = f"{variants} cv features" if variants else "no character variants"
    print(f"{args.out}: {count} encoded glyphs, {suffix}")


if __name__ == "__main__":
    sys.exit(main())
