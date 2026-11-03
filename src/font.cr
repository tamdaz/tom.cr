require "./bitmap"
require "./style"

# Maps a character to the alternate glyph designs available for it, keyed by
# variant number (variant 1 is always the default used when no override applies).
alias Tom::Variants = Hash(Char, Hash(Int32, Array(String)))

module Tom::Font
  # Blank pixel columns inserted between two adjacent glyphs.
  LETTER_SPACING = 2

  # Renders *text* using *variants*, filling spaces with *blank_width* empty
  # columns, and silently skipping unsupported characters. Each character is
  # drawn with its own glyph, so uppercase and lowercase stay distinct.
  #
  # Glyphs are laid out as pixels and only encoded to characters at the very
  # end, so spacing stays the same width on screen in every style even though
  # cells cover a different number of pixels.
  #
  # Characters in *below_baseline* extend under the shared baseline (descenders
  # and the cedilla); every other taller glyph extends above it (accented
  # capitals).
  #
  # Spacing is rounded up to a whole number of cells: a glyph starting halfway
  # through a cell would be sampled across two of them and come out distorted.
  def self.render(
    text : String, variants : Variants, height : Int32, blank_width : Int32,
    variant_overrides : Hash(Char, Int32) = {} of Char => Int32,
    style : Style = Style::DEFAULT,
    below_baseline : Array(Char) = [] of Char,
  ) : String
    glyphs = [] of Bitmap
    below = [] of Bool

    text.each_char do |char|
      if char == ' '
        glyphs << Bitmap.new(align_up(blank_width, style.cell_width), height * 2)
        below << false
      else
        char_variants = variants[char]?
        next unless char_variants

        wanted = variant_overrides[char]?
        glyph = (wanted && char_variants[wanted]?) || char_variants[1]?
        next unless glyph

        glyphs << Bitmap.from_half_blocks(glyph)
        below << below_baseline.includes?(char)
      end
    end

    spacing = align_up(LETTER_SPACING, style.cell_width)
    style.render(compose(glyphs, below, height * 2, spacing))
  end

  # Lays *glyphs* out left to right, separated by *spacing* blank columns.
  # Glyphs may be taller than *height*: accented capitals add two rows above the
  # baseline, while the cedilla and descenders add rows below it. Flagged glyphs
  # hang under the shared baseline; the others sit on it.
  private def self.compose(glyphs : Array(Bitmap), below : Array(Bool), height : Int32, spacing : Int32) : Bitmap
    if glyphs.empty?
      return Bitmap.new(0, height)
    end

    overhang = glyphs.map_with_index do |glyph, index|
      extra = Math.max(0, glyph.height - height)
      below[index] ? {0, extra} : {extra, 0}
    end

    above = overhang.max_of?(&.[0]) || 0
    underneath = overhang.max_of?(&.[1]) || 0

    width = glyphs.sum(&.width) + spacing * (glyphs.size - 1)
    strip = Bitmap.new(width, above + height + underneath)
    baseline = above + height

    x = 0

    glyphs.each_with_index do |glyph, index|
      unless index == 0
        x += spacing
      end

      # The letter's bottom is the glyph's bottom for above-accented glyphs,
      # and sits one overhang above it for below-baseline glyphs.
      top = baseline - (glyph.height - overhang[index][1])
      strip.blit(glyph, x, top)
      x += glyph.width
    end

    strip
  end

  private def self.align_up(value : Int32, unit : Int32) : Int32
    ((value + unit - 1) // unit) * unit
  end
end
