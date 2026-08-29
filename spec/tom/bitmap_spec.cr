require "../spec_helper"

describe Tom::Bitmap do
  it "decodes half blocks into two pixel rows per text row" do
    bitmap = Tom::Bitmap.from_half_blocks(["█▀▄ "])

    bitmap.width.should eq(4)
    bitmap.height.should eq(2)

    # full block, upper half, lower half, blank
    bitmap[0, 0].should be_true
    bitmap[0, 1].should be_true
    bitmap[1, 0].should be_true
    bitmap[1, 1].should be_false
    bitmap[2, 0].should be_false
    bitmap[2, 1].should be_true
    bitmap[3, 0].should be_false
    bitmap[3, 1].should be_false
  end

  it "pads short rows with blanks so the grid stays rectangular" do
    bitmap = Tom::Bitmap.from_half_blocks(["██", "█"])

    bitmap.width.should eq(2)
    bitmap[1, 2].should be_false
    bitmap[1, 3].should be_false
  end

  it "reads out-of-bounds pixels as unset" do
    bitmap = Tom::Bitmap.new(2, 2)

    bitmap[-1, 0].should be_false
    bitmap[0, -1].should be_false
    bitmap[2, 0].should be_false
    bitmap[0, 2].should be_false
  end

  it "copies one bitmap into another at an offset" do
    source = Tom::Bitmap.from_half_blocks(["█"])
    target = Tom::Bitmap.new(3, 2)
    target.blit(source, 2)

    target[2, 0].should be_true
    target[2, 1].should be_true
    target[0, 0].should be_false
  end

  it "grows by blank rows when padded" do
    padded = Tom::Bitmap.from_half_blocks(["█"]).pad_vertical(1, 2)

    padded.height.should eq(5)
    padded[0, 0].should be_false
    padded[0, 1].should be_true
    padded[0, 2].should be_true
    padded[0, 3].should be_false
    padded[0, 4].should be_false
  end
end
