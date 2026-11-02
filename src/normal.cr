require "./font"

# 2-byte VCR OSD font: 10x7 glyphs, full alphabet, digits and accents.
module Tom::Fonts::Normal
  HEIGHT       =  7
  BLANK_WIDTH  = 10
  MAX_VARIANTS =  9

  ACCENT_BASE = {
    'À' => {'A', :above},
    'Á' => {'A', :above},
    'Â' => {'A', :above},
    'Ä' => {'A', :above},
    'Ç' => {'C', :below},
    'È' => {'E', :above},
    'É' => {'E', :above},
    'Ê' => {'E', :above},
    'Ë' => {'E', :above},
    'Ì' => {'I', :above},
    'Í' => {'I', :above},
    'Î' => {'I', :above},
    'Ï' => {'I', :above},
    'Ò' => {'O', :above},
    'Ó' => {'O', :above},
    'Ô' => {'O', :above},
    'Ö' => {'O', :above},
    'Ù' => {'U', :above},
    'Ú' => {'U', :above},
    'Û' => {'U', :above},
    'Ü' => {'U', :above},
  }

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
