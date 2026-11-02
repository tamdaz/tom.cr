require "./font"

# 2-byte VCR OSD font: 10x7 glyphs, full alphabet, digits and accents.
module Tom::Fonts::Normal
  HEIGHT       =  7
  BLANK_WIDTH  = 10
  MAX_VARIANTS =  9

  # Accented characters described by the shared data/accents.tsv manifest:
  # composed character => {base letter, side of the accent}.
  ACCENT_BASE = {% begin %}
    {
    {% for line in read_file("#{__DIR__}/data/accents.tsv").split('\n') %}
      {% fields = line.split('\t') %}
      {% if fields.size == 5 && !fields[0].starts_with?("#") %}
        {{ fields[4].to_i.chr }} => { {{ fields[3].to_i.chr }}, :{{ fields[1].id }} },
      {% end %}
    {% end %}
    }
  {% end %}

  BELOW_BASELINE = ACCENT_BASE.select do |character, (base, side)|
    side == :below
  end

  VARIANTS = begin
    variants = Tom::Variants.new

    {% for code in (33..255).to_a + [9608] %}
      char_variants = Hash(Int32, Array(String)).new

      {% for n in (1..9) %}
        {% content = read_file?("#{__DIR__}/data/#{code}/#{n}.txt") %}

        {% if content %}
          char_variants[{{ n }}] = {{ content }}.chomp.split('\n')
        {% end %}
      {% end %}

      unless char_variants.empty?
        variants[{{ code }}.chr] = char_variants
      end
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
    effective = variant_overrides.dup

    ACCENT_BASE.each do |accented, (base, side)|
      next if effective.has_key?(accented)

      if variant = variant_overrides[base]?
        effective[accented] = variant
      end
    end

    Tom::Font.render(text, VARIANTS, HEIGHT, BLANK_WIDTH, effective, style, BELOW_BASELINE.keys)
  end
end
