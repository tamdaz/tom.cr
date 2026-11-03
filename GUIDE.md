# Tom Mono character variants guide

The generated TTF groups alternate designs into one OpenType **character
variant** feature (`cvXX`) per base character that has alternates. Accented
forms share their base letter's feature. This guide maps every `cv` feature to
the characters it changes.

The mapping below reflects the glyph data in `src/data`. Generate the font and
inspect the current mapping with:

```sh
python3 tools/build_font.py
```

## How variants are numbered

Glyph files use `1.txt` for the default design, then `2.txt`, `3.txt`, … for
alternates:

| Glyph file | CLI selection | OpenType `cv` value | Alternate glyph |
| ---------- | ------------- | ------------------- | --------------- |
| `1.txt`    | `-v X:1`      | `0` (off)           | default         |
| `2.txt`    | `-v X:2`      | `1`                 | `X.alt2`        |
| `3.txt`    | `-v X:3`      | `2`                 | `X.alt3`        |
| `4.txt`    | `-v X:4`      | `3`                 | `X.alt4`        |

The CLI uses the **glyph file number**; the OpenType feature uses the
**alternate number** (`file number - 1`). For example, `src/data/97/2.txt` is
selected with `-v a:2` on the command line and `"cv24" 1` in CSS.

## Letters

| Feature | Base | UI label       | Applies to        | `cv` values | Alternates        |
| ------- | ---- | -------------- | ----------------- | ----------- | ----------------- |
| `cv10`  | `A`  | `A Variants`   | `A À Á Â Ä`       | 1–2         | `alt2`, `alt3`    |
| `cv11`  | `C`  | `C Variants`   | `C Ç`             | 1           | `alt2`            |
| `cv12`  | `D`  | `D Variants`   | `D`               | 1           | `alt2`            |
| `cv13`  | `G`  | `G Variants`   | `G`               | 1–3         | `alt2`–`alt4`     |
| `cv14`  | `I`  | `I Variants`   | `I Ì Í Î Ï`       | 1           | `alt2`            |
| `cv15`  | `J`  | `J Variants`   | `J`               | 1           | `alt2`            |
| `cv16`  | `K`  | `K Variants`   | `K`               | 1           | `alt2`            |
| `cv17`  | `L`  | `L Variants`   | `L`               | 1           | `alt2`            |
| `cv18`  | `O`  | `O Variants`   | `O Ò Ó Ô Ö`       | 1           | `alt2`            |
| `cv19`  | `Q`  | `Q Variants`   | `Q`               | 1–2         | `alt2`, `alt3`    |
| `cv20`  | `R`  | `R Variants`   | `R`               | 1–3         | `alt2`–`alt4`     |
| `cv21`  | `S`  | `S Variants`   | `S`               | 1–3         | `alt2`–`alt4`     |
| `cv22`  | `T`  | `T Variants`   | `T`               | 1           | `alt2`            |
| `cv24`  | `a`  | `a Variants`   | `a à á â ä`       | 1           | `alt2`            |
| `cv25`  | `s`  | `s Variants`   | `s`               | 1           | `alt2`            |

Uppercase and lowercase are independent: `cv10` changes `A` and its uppercase
accents, while `cv24` changes `a` and its lowercase accents. Lowercase letters
without their own alternate art do not appear in a capital's `cv` feature.

## Digits

| Feature | Base | UI label       | Applies to | `cv` values | Alternates     |
| ------- | ---- | -------------- | ---------- | ----------- | -------------- |
| `cv02`  | `0`  | `0 Variants`   | `0`        | 1–2         | `alt2`, `alt3` |
| `cv03`  | `1`  | `1 Variants`   | `1`        | 1           | `alt2`         |
| `cv04`  | `2`  | `2 Variants`   | `2`        | 1–3         | `alt2`–`alt4`  |
| `cv05`  | `3`  | `3 Variants`   | `3`        | 1–3         | `alt2`–`alt4`  |
| `cv06`  | `5`  | `5 Variants`   | `5`        | 1–2         | `alt2`, `alt3` |
| `cv07`  | `6`  | `6 Variants`   | `6`        | 1–3         | `alt2`–`alt4`  |
| `cv08`  | `7`  | `7 Variants`   | `7`        | 1           | `alt2`         |
| `cv09`  | `9`  | `9 Variants`   | `9`        | 1           | `alt2`         |

`4` and `8` currently have no alternate designs.

## Punctuation

| Feature | Base | UI label         | Applies to | `cv` values | Alternates |
| ------- | ---- | ---------------- | ---------- | ----------- | ---------- |
| `cv01`  | `$`  | `$ Variants`     | `$`        | 1           | `alt2`     |
| `cv23`  | `\`  | `\ Variants`     | `\`        | 1           | `alt2`     |

## Feature order

`cv` numbers are assigned in ascending base-codepoint order for every character
that has at least one alternate design. Adding variants for a character earlier
in that order shifts the numbers of the features after it. If you depend on
specific `cv` numbers, regenerate the font and re-check this table after adding
glyph variants.

There are currently **no stylistic set features** (`ss01`–`ss20`) in the TTF.

## Using a variant

Command line (case-sensitive):

```sh
bin/tom -v a:2 "a"     # lowercase a, variant 2
bin/tom -v A:2 "A"     # uppercase A, variant 2
bin/tom -v S:2 "S"     # uppercase S, variant 2
bin/tom -v s:2 "s"     # lowercase s, variant 2
```

CSS:

```css
/* First alternate for lowercase a (a.alt2) */
.lowercase-a {
  font-feature-settings: "cv24" 1;
}

/* Second alternate for uppercase A (A.alt3) */
.uppercase-a {
  font-feature-settings: "cv10" 2;
}
```

OpenType-aware applications normally show these features by their UI label,
such as `A Variants`, `a Variants`, or `0 Variants`.
