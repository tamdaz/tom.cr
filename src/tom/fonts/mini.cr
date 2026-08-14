require "../font"

# Mini VCR OSD font: dense ~5x4 glyphs using Unicode sextants/octants, alphabet and digits.
module Tom::Fonts::Mini
  HEIGHT       = 4
  BLANK_WIDTH  = 5
  MAX_VARIANTS = 9

  VARIANTS = begin
    variants = Tom::Variants.new

    {% for code in (65..90).to_a + (48..57).to_a %}
      char_variants = Hash(Int32, Tom::Glyph).new

      {% for n in (1..9) %}
        {% content = read_file?("#{__DIR__}/data/mini/#{code}/#{n}.txt") %}
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
