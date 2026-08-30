require "./bitmap"
require "./style"

# A glyph is the set of rows (top to bottom) that make up one rendered character.
alias Tom::Glyph = Array(String)

# Maps a character to the alternate glyph designs available for it, keyed by
# variant number (variant 1 is always the default used when no override applies).
alias Tom::Variants = Hash(Char, Hash(Int32, Tom::Glyph))

module Tom::Font
  # Blank pixel columns inserted between two adjacent glyphs.
  LETTER_SPACING = 1

  # Renders *text* using *variants*, uppercasing input, filling spaces with
  # *blank_width* empty columns, and silently skipping unsupported characters.
  #
  # Glyphs are laid out as pixels and only encoded to characters at the very
  # end, so spacing stays the same width on screen in every style even though
  # cells cover a different number of pixels.
  #
  # Spacing is rounded up to a whole number of cells: a glyph starting halfway
  # through a cell would be sampled across two of them and come out distorted.
  def self.render(
    text : String, variants : Variants, height : Int32, blank_width : Int32,
    variant_overrides : Hash(Char, Int32) = {} of Char => Int32,
    style : Style = Style::DEFAULT,
  ) : String
    glyphs = [] of Bitmap

    text.upcase.each_char do |char|
      if char == ' '
        glyphs << Bitmap.new(align_up(blank_width, style.cell_width), height * 2)
      else
        char_variants = variants[char]?
        next unless char_variants

        wanted = variant_overrides[char]?
        glyph = (wanted && char_variants[wanted]?) || char_variants[1]?
        next unless glyph

        glyphs << Bitmap.from_half_blocks(glyph)
      end
    end

    spacing = align_up(LETTER_SPACING, style.cell_width)
    style.render(compose(glyphs, height * 2, spacing))
  end

  # Lays *glyphs* out left to right, separated by *spacing* blank columns.
  private def self.compose(glyphs : Array(Bitmap), height : Int32, spacing : Int32) : Bitmap
    return Bitmap.new(0, height) if glyphs.empty?

    width = glyphs.sum(&.width) + spacing * (glyphs.size - 1)
    strip = Bitmap.new(width, height)

    x = 0
    glyphs.each_with_index do |glyph, index|
      x += spacing unless index == 0
      strip.blit(glyph, x)
      x += glyph.width
    end

    strip
  end

  private def self.align_up(value : Int32, unit : Int32) : Int32
    ((value + unit - 1) // unit) * unit
  end
end
