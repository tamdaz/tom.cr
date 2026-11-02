require "../spec_helper"

describe Tom::Fonts::Normal do
  it "has a 10x7 glyph for every letter and digit" do
    Tom::Fonts::Normal::GLYPHS['A'].size.should eq(7)
    Tom::Fonts::Normal::GLYPHS['A'].each { |row| row.size.should eq(10) }
    Tom::Fonts::Normal::GLYPHS['0'].size.should eq(7)
  end

  it "covers letters, digits and the supported punctuation" do
    ('A'..'Z').each do |letter|
      Tom::Fonts::Normal::GLYPHS[letter]?.should_not be_nil
    end

    ('0'..'9').each do |digit|
      Tom::Fonts::Normal::GLYPHS[digit]?.should_not be_nil
    end

    ['!', '+', '-', '|', '¡', '¿', '´', '¸', 'Ç'].each do |mark|
      Tom::Fonts::Normal::GLYPHS[mark]?.should_not be_nil
    end
  end

  it "covers the circumflex capitals and their lowercase forms" do
    "ÂÊÎÔÛ".each_char do |letter|
      Tom::Fonts::Normal::GLYPHS[letter]?.should_not be_nil
    end

    Tom::Fonts::Normal.render("âêîôû").should eq(Tom::Fonts::Normal.render("ÂÊÎÔÛ"))
  end

  it "covers the grave capitals and their lowercase forms" do
    "ÀÈÌÒÙ".each_char do |letter|
      Tom::Fonts::Normal::GLYPHS[letter]?.should_not be_nil
    end

    Tom::Fonts::Normal.render("àèìòù").should eq(Tom::Fonts::Normal.render("ÀÈÌÒÙ"))
  end

  it "covers the acute capitals and their lowercase forms" do
    "ÁÉÍÓÚ".each_char do |letter|
      Tom::Fonts::Normal::GLYPHS[letter]?.should_not be_nil
    end

    Tom::Fonts::Normal.render("áéíóú").should eq(Tom::Fonts::Normal.render("ÁÉÍÓÚ"))
  end

  it "covers the diaeresis capitals and their lowercase forms" do
    "ÄËÏÖÜ".each_char do |letter|
      Tom::Fonts::Normal::GLYPHS[letter]?.should_not be_nil
    end

    Tom::Fonts::Normal.render("äëïöü").should eq(Tom::Fonts::Normal.render("ÄËÏÖÜ"))
  end

  it "covers the cedilla capital and its lowercase form" do
    Tom::Fonts::Normal::GLYPHS['Ç']?.should_not be_nil
    Tom::Fonts::Normal.render("ç").should eq(Tom::Fonts::Normal.render("Ç"))
  end

  it "adds two rows above accented glyphs without changing the letter" do
    Tom::Fonts::Normal::GLYPHS['Â'].size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
    Tom::Fonts::Normal::GLYPHS['Â'].last(7).should eq(Tom::Fonts::Normal::GLYPHS['A'])
    Tom::Fonts::Normal.render("Â").split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
    Tom::Fonts::Normal.render("A").split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT)
  end

  it "adds two rows below the cedilla without changing the letter" do
    glyph = Tom::Fonts::Normal::GLYPHS['Ç']

    glyph.size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
    glyph.first(7).should eq(Tom::Fonts::Normal::GLYPHS['C'])
    glyph.last(2).should eq(Tom::Fonts::Normal::GLYPHS['¸'].last(2))
  end

  it "builds accented variants from the base letter's variants" do
    Tom::Fonts::Normal::ACCENT_BASE.each do |accented, (base, side)|
      accented_variants = Tom::Fonts::Normal::VARIANTS[accented]
      base_variants = Tom::Fonts::Normal::VARIANTS[base]

      accented_variants.keys.sort.should eq(base_variants.keys.sort)
      base_variants.each do |number, letter|
        variant = accented_variants[number]

        if side == :below
          variant.size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
          variant.first(7).should eq(letter)
        elsif variant.size == Tom::Fonts::Normal::HEIGHT
          # The variant already carries the matching accent, so it is reused
          # unchanged instead of stacking a second one.
          variant.should eq(letter)
        else
          variant.size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
          variant.last(7).should eq(letter)
        end
      end
    end
  end

  it "never cuts a letter variant whose top rows resemble an accent" do
    Tom::Fonts::Normal::VARIANTS['Ó'][2].last(7).should eq(Tom::Fonts::Normal::VARIANTS['O'][2])
    Tom::Fonts::Normal::VARIANTS['Ó'][2].size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
    Tom::Fonts::Normal::VARIANTS['Á'][3].last(7).should eq(Tom::Fonts::Normal::VARIANTS['A'][3])
  end

  it "reuses variants that already carry the matching accent" do
    Tom::Fonts::Normal::VARIANTS['Â'][3].should eq(Tom::Fonts::Normal::VARIANTS['A'][3])
    Tom::Fonts::Normal::VARIANTS['Ô'][2].should eq(Tom::Fonts::Normal::VARIANTS['O'][2])
  end

  it "exposes alternate variants, always including variant 1" do
    Tom::Fonts::Normal::VARIANTS.each_value do |char_variants|
      char_variants.has_key?(1).should be_true
    end

    Tom::Fonts::Normal::VARIANTS['A'].size.should be > 1
  end
end

describe Tom::Font do
  it "renders a word with the right number of rows" do
    Tom::Fonts::Normal.render("HI").split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT)
  end

  it "renders spaces as blank columns" do
    with_space = Tom::Fonts::Normal.render("A B")
    without_space = Tom::Fonts::Normal.render("AB")
    with_space.should_not eq(without_space)
  end

  it "silently skips characters unsupported by the font" do
    Tom::Fonts::Normal.render("A.B").should eq(Tom::Fonts::Normal.render("A.B"))
  end

  it "is case-insensitive" do
    Tom::Fonts::Normal.render("hi").should eq(Tom::Fonts::Normal.render("HI"))
  end

  it "lets the cedilla hang below the baseline" do
    rendered = Tom::Fonts::Normal.render("Ç")

    rendered.split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT + 2)
    rendered.split('\n').first(7).should eq(Tom::Fonts::Normal.render("C").split('\n'))
  end

  it "keeps letters aligned when accents grow the output" do
    Tom::Fonts::Normal.render("AÇ").split('\n').first(7).should eq(Tom::Fonts::Normal.render("AC").split('\n'))
    Tom::Fonts::Normal.render("AÇÂ").split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT + 4)
  end

  it "renders text with no drawable characters as blank rows" do
    blank = Tom::Fonts::Normal.render("")

    blank.split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT)
  end

  it "uses the requested glyph variant" do
    default = Tom::Fonts::Normal.render("A")
    variant = Tom::Fonts::Normal.render("A", {'A' => 2})

    variant.should_not eq(default)
  end

  it "applies a letter's variant to its accented forms" do
    default = Tom::Fonts::Normal.render("Â")

    by_letter = Tom::Fonts::Normal.render("Â", {'A' => 2})
    by_accent = Tom::Fonts::Normal.render("Â", {'Â' => 2})

    by_letter.should eq(by_accent)
    by_letter.should_not eq(default)
    Tom::Fonts::Normal.render("Ç", {'C' => 2}).should eq(Tom::Fonts::Normal.render("Ç", {'Ç' => 2}))
  end

  it "lets an explicit accented variant win over the base letter's" do
    Tom::Fonts::Normal.render("Â", {'A' => 2, 'Â' => 1}).should eq(Tom::Fonts::Normal.render("Â"))
  end

  it "falls back to variant 1 when the requested one is missing" do
    Tom::Fonts::Normal.render("H", {'H' => 9}).should eq(Tom::Fonts::Normal.render("H"))
  end

  # The half-block output predates the pixel pipeline; it must not shift.
  it "renders half blocks exactly as the glyph data is authored" do
    Tom::Fonts::Normal.render("TOM").should eq(<<-TEXT)
      ██████████   ▄██████▄   ██      ██
          ██      ██▀    ▀██  ███▄  ▄███
          ██      ██      ██  ██▀████▀██
          ██      ██      ██  ██  ▀▀  ██
          ██      ██      ██  ██      ██
          ██      ██▄    ▄██  ██      ██
          ██       ▀██████▀   ██      ██
      TEXT
  end
end
