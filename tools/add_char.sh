#!/usr/bin/env fish

# Create a glyph variant under src/data/<decimal codepoint>/<variant>.txt.
#
# Usage:
#   tools/add_char.sh [CODEPOINT] [VARIANT]
#
# CODEPOINT accepts a decimal number (65), a hex number (0x41 or U+0041) or a
# single character (A). VARIANT is a number from 1 to 9 and defaults to 1.
#
# Variant 1 starts as a blank 10x7 half-block grid. Variants 2-9 start as a
# copy of variant 1, so only the pixels that differ need editing.

set -l script (realpath (status --current-filename))
set -l root (realpath (dirname $script)/..)
set -l data_dir $root/src/data
set -g max_variants 9
set -l glyph_width 10
set -l glyph_height 7

function usage
    printf 'Usage: %s [CODEPOINT] [VARIANT]\n\n' (basename (status --current-filename))
    echo "  CODEPOINT  decimal (65), hex (0x41, U+0041) or a single character (A)"
    echo "  VARIANT    glyph variant from 1 to $max_variants (default: 1)"
    echo
    echo "Creates src/data/<decimal codepoint>/<variant>.txt."
    echo "Variant 1 starts blank; variants 2-9 copy variant 1 as a starting point."
end

# Prints the decimal code point for a decimal, hex or single-character input.
function parse_codepoint
    set -l input $argv[1]
    set -l code

    if string match -qr '^[0-9]+$' -- $input
        set code (math "$input")
    else if string match -qr '^[Uu]\+[0-9A-Fa-f]+$' -- $input
        set -l hex (string sub -s 3 -- $input)
        set code (math "0x$hex")
    else if string match -qr '^0[xX][0-9A-Fa-f]+$' -- $input
        set code (math "$input")
    else if string match -qr '^.$' -- $input
        set code (printf '%d' "'$input")
    else
        return 1
    end

    if test $code -lt 0 -o $code -gt 1114111
        return 1
    end

    # Surrogates are not valid Unicode scalar values.
    if test $code -ge 55296 -a $code -le 57343
        return 1
    end

    echo $code
end

set -l positional
for arg in $argv
    switch $arg
        case -h --help
            usage
            exit 0
        case '-*'
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 1
        case '*'
            set -a positional $arg
    end
end

if test (count $positional) -gt 2
    usage >&2
    exit 1
end

set -l input
if test (count $positional) -ge 1
    set input $positional[1]
else if isatty stdin
    read -P "Codepoint (decimal, 0x.../U+... or a character): " input
else
    echo "Missing CODEPOINT." >&2
    usage >&2
    exit 1
end

set -l codepoint (parse_codepoint $input)
if test $status -ne 0
    echo "Invalid code point: $input" >&2
    exit 1
end

set -l variant
if test (count $positional) -ge 2
    set variant $positional[2]
else if isatty stdin
    read -P "Variant number [1]: " variant
    if test -z "$variant"
        set variant 1
    end
else
    set variant 1
end

if not string match -qr '^[1-9]$' -- $variant
    echo "Variant must be a number from 1 to $max_variants." >&2
    exit 1
end

set -l dir $data_dir/$codepoint
set -l path $dir/$variant.txt

if test -e $path
    echo "Already exists: $path" >&2
    echo "Edit that file, or remove it first to recreate it." >&2
    exit 1
end

if test $variant -gt 1 -a ! -f $dir/1.txt
    echo "Variant 1 is missing for code point $codepoint. Create it first." >&2
    exit 1
end

mkdir -p $dir

if test $variant -eq 1
    for row in (seq $glyph_height)
        string repeat -n $glyph_width ' '
    end >$path
    echo "Created blank glyph for code point $codepoint: $path"
else
    cp $dir/1.txt $path
    echo "Created variant $variant from variant 1: $path"
end
