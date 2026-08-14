# A glyph is the set of rows (top to bottom) that make up one rendered character.
alias Tom::Glyph = Array(String)

# Maps a character to the alternate glyph designs available for it, keyed by
# variant number (variant 1 is always the default used when no override applies).
alias Tom::Variants = Hash(Char, Hash(Int32, Tom::Glyph))

module Tom::Font
  # Renders *text* using *variants*, uppercasing input, filling spaces with
  # *blank_width* empty columns, and silently skipping unsupported characters.
  # *style* selects an alternate glyph variant per character (falls back to
  # variant 1 when a character has no override or the requested variant
  # doesn't exist for it).
  def self.render(text : String, variants : Variants, height : Int32, blank_width : Int32, style : Hash(Char, Int32) = {} of Char => Int32) : String
    rows = Array.new(height) { [] of String }

    text.upcase.each_char do |char|
      if char == ' '
        glyph = Glyph.new(height) { " " * blank_width }
      else
        char_variants = variants[char]?
        next unless char_variants

        wanted = style[char]?
        glyph = (wanted && char_variants[wanted]?) || char_variants[1]?
        next unless glyph
      end

      height.times { |i| rows[i] << glyph[i] }
    end

    rows.map(&.join(' ')).join('\n')
  end
end
