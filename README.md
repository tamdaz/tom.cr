# tom

![tom_banner_terminal](img/banner.png)

Tom _(Terminal On-screen display Mono)_ is a tool that allows to display the VCR OSD mono-like font on your terminal.

## Installation

You can install the program via the [GitHub relases](https://github.com/tamdaz/tom.cr/releases), or via:

```sh
shards install
```

## Usage

```
Usage: tom [options] TEXT
    -s NAME, --style=NAME            Block characters to draw with: half, octant, braille (default: half)
    -v LETTER:N,..., --variant=LETTER:N,...
                                     Use glyph variant N for a given letter, e.g. S:2 or s:2 (case-sensitive, repeatable)
    -h, --help                       Show this help
```

```sh
tom HELLO
```

![result hello](img/hello-normal.png)

Text is rendered as typed: `tom hello` uses the lowercase glyphs directly,
including accents and descenders such as `p` and `j`. See
[GUIDE.md](GUIDE.md) for the generated TTF's character-variant (`cvXX`) map.

Three block styles are available via `-s`, all built from the same glyph data
so letter spacing stays the same width on screen whatever style you pick:

| Style                | Cell size    | Looks like                          |
| -------------------- | ------------ | ----------------------------------- |
| `half` _(default)_   | 1x2 pixels   | classic half blocks (`▀` `▄` `█`)   |
| `octant`             | 2x4 pixels   | finer, Unicode 16 block octants     |
| `braille`            | 2x4 pixels   | finest, Braille patterns            |

```sh
tom -s octant HELLO
```

![result hello octant](img/hello-octant.png)

![result hello braille](img/hello-braille.png)

The display of Braille characters may vary depending on your device. Some of them may not display correctly.

## Development

```sh
crystal spec
shards build tom
```

Glyphs live one code point per directory, as half-block art: `src/data/<code>/<variant>.txt` _(e.g. `src/data/65/1.txt` for `A`, variant 1)_. Each file is a 10x7 grid drawn with `▀`, `▄`, `█` and spaces — octant and braille output are derived from this at render time. Taller grids, up to 10x11, add rows for accents above the letter or for descenders below it: a descender such as `p` or `j` uses the rows after the 7-row body for its tail. Lowercase letters keep the two rows above the x-height free for the accent (blank, or the dot on `i`), so accented lowercase stays 10x7; only the lowercase cedilla adds rows below. Every extra variant becomes an alternate in that character's own `cvXX` feature, so a lowercase letter with its own art keeps its own feature instead of sharing the capital's.

Scaffold a new character or variant with:

```sh
tools/add_char.sh 65 2    # variant 2 of A, copied from variant 1
tools/add_char.sh A 2     # same thing, using the character directly
```

Variant 1 starts as a blank grid; later variants copy variant 1 so only the
pixels that differ need editing.

## Contributing

1. Fork it (<https://github.com/tamdaz/tom.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Zohir Tamda](https://github.com/tamdaz) - creator and maintainer
