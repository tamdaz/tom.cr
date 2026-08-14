require "../spec_helper"

describe Tom::Fonts::Wide do
  it "has a 10x7 glyph for every letter and digit" do
    Tom::Fonts::Wide::GLYPHS['A'].size.should eq(7)
    Tom::Fonts::Wide::GLYPHS['A'].each { |row| row.size.should eq(10) }
    Tom::Fonts::Wide::GLYPHS['0'].size.should eq(7)
  end
end

describe Tom::Fonts::Compact do
  it "has a 5x7 glyph for every letter" do
    Tom::Fonts::Compact::GLYPHS['A'].size.should eq(7)
    Tom::Fonts::Compact::GLYPHS['A'].each { |row| row.size.should eq(5) }
  end

  it "does not cover digits" do
    Tom::Fonts::Compact::GLYPHS['0']?.should be_nil
  end
end

describe Tom::Fonts::Mini do
  it "has a 4-row glyph for every letter and digit" do
    Tom::Fonts::Mini::GLYPHS['A'].size.should eq(4)
    Tom::Fonts::Mini::GLYPHS['0'].size.should eq(4)
  end
end
