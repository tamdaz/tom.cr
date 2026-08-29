require "../spec_helper"

describe Tom::Fonts::Normal do
  it "has a 10x7 glyph for every letter and digit" do
    Tom::Fonts::Normal::GLYPHS['A'].size.should eq(7)
    Tom::Fonts::Normal::GLYPHS['A'].each { |row| row.size.should eq(10) }
    Tom::Fonts::Normal::GLYPHS['0'].size.should eq(7)
  end

  it "covers letters, digits and the supported punctuation" do
    ('A'..'Z').each { |letter| Tom::Fonts::Normal::GLYPHS[letter]?.should_not be_nil }
    ('0'..'9').each { |digit| Tom::Fonts::Normal::GLYPHS[digit]?.should_not be_nil }
    ['!', '+', '-', '|'].each { |mark| Tom::Fonts::Normal::GLYPHS[mark]?.should_not be_nil }
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
    Tom::Fonts::Normal.render("A#B").should eq(Tom::Fonts::Normal.render("AB"))
  end

  it "is case-insensitive" do
    Tom::Fonts::Normal.render("hi").should eq(Tom::Fonts::Normal.render("HI"))
  end

  # The CLI rejects empty input before reaching this point; kept as-is so
  # library callers see the same output as before the pixel pipeline.
  it "renders text with no drawable characters as blank rows" do
    blank = Tom::Fonts::Normal.render("")

    blank.split('\n').size.should eq(Tom::Fonts::Normal::HEIGHT)
    blank.should eq(Tom::Fonts::Normal.render("#"))
  end

  it "uses the requested glyph variant" do
    default = Tom::Fonts::Normal.render("A")
    variant = Tom::Fonts::Normal.render("A", {'A' => 2})

    variant.should_not eq(default)
  end

  it "falls back to variant 1 when the requested one is missing" do
    Tom::Fonts::Normal.render("H", {'H' => 9}).should eq(Tom::Fonts::Normal.render("H"))
  end

  # The half-block output predates the pixel pipeline; it must not shift.
  it "renders half blocks exactly as the glyph data is authored" do
    Tom::Fonts::Normal.render("TOM").should eq(<<-ART)
      ██████████  ▄██████▄  ██      ██
          ██     ██▀    ▀██ ███▄  ▄███
          ██     ██      ██ ██▀████▀██
          ██     ██      ██ ██  ▀▀  ██
          ██     ██      ██ ██      ██
          ██     ██▄    ▄██ ██      ██
          ██      ▀██████▀  ██      ██
      ART
  end
end
