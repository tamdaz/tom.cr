require "./font"

# 2-byte VCR OSD font: 10x7 glyphs, full alphabet and digits.
module Tom::Fonts::Normal
  HEIGHT       =  7
  BLANK_WIDTH  = 10
  MAX_VARIANTS =  9

  VARIANTS = begin
    variants = Tom::Variants.new

    {% for code in (33..126).to_a + [9608] %}
      char_variants = Hash(Int32, Tom::Glyph).new

      {% for n in (1..9) %}
        {% content = read_file?("#{__DIR__}/data/#{code}/#{n}.txt") %}
        
        {% if content %}
          char_variants[{{ n }}] = {{ content }}.chomp.split('\n')
        {% end %}
      {% end %}

      variants[{{ code }}.chr] = char_variants unless char_variants.empty?
    {% end %}

    variants
  end

  GLYPHS = VARIANTS.transform_values do |char_variants|
    char_variants[1]
  end

  def self.render(
    text : String,
    variant_overrides : Hash(Char, Int32) = {} of Char => Int32,
    style : Tom::Style = Tom::Style::DEFAULT,
  ) : String
    Tom::Font.render(text, VARIANTS, HEIGHT, BLANK_WIDTH, variant_overrides, style)
  end
end
