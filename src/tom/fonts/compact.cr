require "../font"

# 1-byte VCR OSD font: compact 5x7 glyphs, alphabet only.
module Tom::Fonts::Compact
  HEIGHT       = 7
  BLANK_WIDTH  = 5
  MAX_VARIANTS = 9

  VARIANTS = begin
    variants = Tom::Variants.new

    {% for code in (65..90) %}
      char_variants = Hash(Int32, Tom::Glyph).new

      {% for n in (1..9) %}
        {% content = read_file?("#{__DIR__}/data/compact/#{code}/#{n}.txt") %}
        {% if content %}
          char_variants[{{ n }}] = {{ content }}.chomp.split('\n')
        {% end %}
      {% end %}

      variants[{{ code }}.chr] = char_variants unless char_variants.empty?
    {% end %}

    variants
  end

  GLYPHS = VARIANTS.transform_values { |char_variants| char_variants[1] }

  def self.render(text : String, style : Hash(Char, Int32) = {} of Char => Int32) : String
    Tom::Font.render(text, VARIANTS, HEIGHT, BLANK_WIDTH, style)
  end
end
