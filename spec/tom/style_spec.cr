require "../spec_helper"

# A 2x4 pixel bitmap with the given cells set, listed row-major.
private def cell_of(*set : Int32) : Tom::Bitmap
  bitmap = Tom::Bitmap.new(2, 4)
  set.each { |index| bitmap[index % 2, index // 2] = true }
  bitmap
end

describe Tom::Style do
  it "looks styles up by name" do
    Tom::Style.names.should eq(["half", "octant", "braille"])
    Tom::Style["half"]?.should be_a(Tom::Style::Half)
    Tom::Style["octant"]?.should be_a(Tom::Style::Octant)
    Tom::Style["braille"]?.should be_a(Tom::Style::Braille)
    Tom::Style["bogus"]?.should be_nil
  end

  it "defaults to half blocks" do
    Tom::Style::DEFAULT.should be_a(Tom::Style::Half)
  end

  describe "vertical padding" do
    it "adds nothing when the height already fills whole cells" do
      Tom::Style["octant"].padding_for(16).should eq({0, 0})
      Tom::Style["half"].padding_for(14).should eq({0, 0})
    end

    # 14px of glyph in 4px cells leaves 2px to spread, one on each side, which
    # keeps horizontal bars centred instead of hugging a cell edge.
    it "centres the glyph, biasing the extra pixel upwards" do
      Tom::Style["octant"].padding_for(14).should eq({1, 1})
      Tom::Style["octant"].padding_for(13).should eq({1, 2})
    end
  end

  describe Tom::Style::Half do
    it "round-trips every glyph in the font unchanged" do
      style = Tom::Style["half"]

      Tom::Fonts::Normal::VARIANTS.each do |char, char_variants|
        char_variants.each do |number, glyph|
          encoded = style.render(Tom::Bitmap.from_half_blocks(glyph))
          encoded.should eq(glyph.join('\n')), "#{char.inspect} variant #{number}"
        end
      end
    end
  end

  describe Tom::Style::Braille do
    it "maps an empty cell to the blank braille pattern, not a space" do
      Tom::Style["braille"].render(Tom::Bitmap.new(2, 4)).should eq("⠀")
    end

    it "maps a full cell to all eight dots" do
      Tom::Style["braille"].render(cell_of(0, 1, 2, 3, 4, 5, 6, 7)).should eq("⣿")
    end

    # The dot numbering is column-first for rows 1-3, with row 4 in the high
    # bits -- the easiest part of this to get wrong.
    it "places each dot at its standard bit" do
      style = Tom::Style["braille"]

      style.render(cell_of(0)).should eq((0x2800 + 0x01).chr.to_s) # top-left
      style.render(cell_of(1)).should eq((0x2800 + 0x08).chr.to_s) # top-right
      style.render(cell_of(2)).should eq((0x2800 + 0x02).chr.to_s)
      style.render(cell_of(3)).should eq((0x2800 + 0x10).chr.to_s)
      style.render(cell_of(4)).should eq((0x2800 + 0x04).chr.to_s)
      style.render(cell_of(5)).should eq((0x2800 + 0x20).chr.to_s)
      style.render(cell_of(6)).should eq((0x2800 + 0x40).chr.to_s) # bottom-left
      style.render(cell_of(7)).should eq((0x2800 + 0x80).chr.to_s) # bottom-right
    end
  end

  describe Tom::Style::Octant do
    it "covers all 256 patterns with distinct characters" do
      Tom::Style::Octant::CODEPOINTS.size.should eq(256)
      Tom::Style::Octant::CODEPOINTS.to_a.uniq.size.should eq(256)
    end

    it "reuses the pre-existing block elements where Unicode already had one" do
      style = Tom::Style["octant"]

      style.render(Tom::Bitmap.new(2, 4)).should eq(" ")
      style.render(cell_of(0, 1, 2, 3, 4, 5, 6, 7)).should eq("█")
      style.render(cell_of(0, 1, 2, 3)).should eq("▀")
      style.render(cell_of(4, 5, 6, 7)).should eq("▄")
      style.render(cell_of(0, 2, 4, 6)).should eq("▌")
      style.render(cell_of(1, 3, 5, 7)).should eq("▐")
    end

    it "uses the Unicode 16 block octants for the other patterns" do
      # BLOCK OCTANT-3 (upper-left pixel of the second row only).
      Tom::Style["octant"].render(cell_of(2)).should eq(0x1CD00.chr.to_s)
    end
  end

  describe "geometry" do
    it "renders 2x4 styles as one line per four pixel rows" do
      ["octant", "braille"].each do |name|
        rendered = Tom::Fonts::Normal.render("HI", style: Tom::Style[name])
        lines = rendered.split('\n')

        lines.size.should eq(4)
        lines.map(&.size).uniq.size.should eq(1)
      end
    end

    it "keeps every style the same width on screen in cells" do
      pixels = Tom::Fonts::Normal.render("HI").split('\n').first.size

      ["octant", "braille"].each do |name|
        rendered = Tom::Fonts::Normal.render("HI", style: Tom::Style[name])
        # Letter spacing is rounded up to a whole cell, so a 2px-wide cell
        # buys one extra pixel of gap per inter-glyph boundary.
        rendered.split('\n').first.size.should eq((pixels + 1) // 2)
      end
    end

    it "renders every style without raising" do
      Tom::Style.names.each do |name|
        Tom::Fonts::Normal.render("HI", style: Tom::Style[name]).should_not be_empty
      end
    end
  end
end
