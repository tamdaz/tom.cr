require "./bitmap"

# Encodes a pixel bitmap into text, one character per cell.
#
# Each style covers a different number of pixels per cell, which is what makes
# octant and braille output finer than half blocks without touching the glyph
# data: the same bitmap is simply sampled at a different granularity.
abstract struct Tom::Style
  # Pixels covered by a single output character.
  abstract def cell_width : Int32
  abstract def cell_height : Int32

  # Returns the character covering the cell whose top-left pixel is (x, y).
  abstract def cell(bitmap : Bitmap, x : Int32, y : Int32) : Char

  # Blank pixel rows to add above and below a *height*-pixel bitmap so it fills
  # whole cells. Split evenly, top-biased on an odd remainder, which keeps
  # glyphs vertically centred instead of hugging one edge of the cell.
  def padding_for(height : Int32) : {Int32, Int32}
    remainder = height % cell_height
    return {0, 0} if remainder == 0

    missing = cell_height - remainder
    {missing // 2, missing - missing // 2}
  end

  def render(bitmap : Bitmap) : String
    top, bottom = padding_for(bitmap.height)
    padded = bitmap.pad_vertical(top, bottom)

    String.build do |io|
      (0...padded.height).step(cell_height) do |y|
        io << '\n' unless y == 0
        (0...padded.width).step(cell_width) do |x|
          io << cell(padded, x, y)
        end
      end
    end
  end

  # 1x2 pixels per cell, using the Block Elements the glyph files are authored
  # in. Rendering in this style round-trips the data unchanged.
  struct Half < Style
    def cell_width : Int32
      1
    end

    def cell_height : Int32
      2
    end

    def cell(bitmap : Bitmap, x : Int32, y : Int32) : Char
      top = bitmap[x, y]
      bottom = bitmap[x, y + 1]

      if top && bottom
        '█'
      elsif top
        '▀'
      elsif bottom
        '▄'
      else
        ' '
      end
    end
  end

  # Shared 2x4 geometry: pixels are gathered into an 8-bit mask, read
  # row-major (bit 0 is the top-left pixel, bit 7 the bottom-right).
  abstract struct Cell2x4 < Style
    def cell_width : Int32
      2
    end

    def cell_height : Int32
      4
    end

    def mask(bitmap : Bitmap, x : Int32, y : Int32) : Int32
      mask = 0
      4.times do |row|
        2.times do |column|
          mask |= 1 << (row * 2 + column) if bitmap[x + column, y + row]
        end
      end
      mask
    end
  end

  # 2x4 pixels per cell using the Unicode 16 "Symbols for Legacy Computing
  # Supplement" block octants, falling back to the pre-existing Block Elements
  # for the 26 patterns that already had a character (halves, quadrants,
  # eighths, full block, space).
  #
  # Needs a font covering U+1CD00-U+1CDE5; terminals without it show tofu.
  struct Octant < Cell2x4
    # Indexed by the 8-bit mask built in Cell2x4#mask.
    CODEPOINTS = StaticArray[
      0x00020, 0x1CEA8, 0x1CEAB, 0x1FB82, 0x1CD00, 0x02598, 0x1CD01, 0x1CD02,
      0x1CD03, 0x1CD04, 0x0259D, 0x1CD05, 0x1CD06, 0x1CD07, 0x1CD08, 0x02580,
      0x1CD09, 0x1CD0A, 0x1CD0B, 0x1CD0C, 0x1FBE6, 0x1CD0D, 0x1CD0E, 0x1CD0F,
      0x1CD10, 0x1CD11, 0x1CD12, 0x1CD13, 0x1CD14, 0x1CD15, 0x1CD16, 0x1CD17,
      0x1CD18, 0x1CD19, 0x1CD1A, 0x1CD1B, 0x1CD1C, 0x1CD1D, 0x1CD1E, 0x1CD1F,
      0x1FBE7, 0x1CD20, 0x1CD21, 0x1CD22, 0x1CD23, 0x1CD24, 0x1CD25, 0x1CD26,
      0x1CD27, 0x1CD28, 0x1CD29, 0x1CD2A, 0x1CD2B, 0x1CD2C, 0x1CD2D, 0x1CD2E,
      0x1CD2F, 0x1CD30, 0x1CD31, 0x1CD32, 0x1CD33, 0x1CD34, 0x1CD35, 0x1FB85,
      0x1CEA3, 0x1CD36, 0x1CD37, 0x1CD38, 0x1CD39, 0x1CD3A, 0x1CD3B, 0x1CD3C,
      0x1CD3D, 0x1CD3E, 0x1CD3F, 0x1CD40, 0x1CD41, 0x1CD42, 0x1CD43, 0x1CD44,
      0x02596, 0x1CD45, 0x1CD46, 0x1CD47, 0x1CD48, 0x0258C, 0x1CD49, 0x1CD4A,
      0x1CD4B, 0x1CD4C, 0x0259E, 0x1CD4D, 0x1CD4E, 0x1CD4F, 0x1CD50, 0x0259B,
      0x1CD51, 0x1CD52, 0x1CD53, 0x1CD54, 0x1CD55, 0x1CD56, 0x1CD57, 0x1CD58,
      0x1CD59, 0x1CD5A, 0x1CD5B, 0x1CD5C, 0x1CD5D, 0x1CD5E, 0x1CD5F, 0x1CD60,
      0x1CD61, 0x1CD62, 0x1CD63, 0x1CD64, 0x1CD65, 0x1CD66, 0x1CD67, 0x1CD68,
      0x1CD69, 0x1CD6A, 0x1CD6B, 0x1CD6C, 0x1CD6D, 0x1CD6E, 0x1CD6F, 0x1CD70,
      0x1CEA0, 0x1CD71, 0x1CD72, 0x1CD73, 0x1CD74, 0x1CD75, 0x1CD76, 0x1CD77,
      0x1CD78, 0x1CD79, 0x1CD7A, 0x1CD7B, 0x1CD7C, 0x1CD7D, 0x1CD7E, 0x1CD7F,
      0x1CD80, 0x1CD81, 0x1CD82, 0x1CD83, 0x1CD84, 0x1CD85, 0x1CD86, 0x1CD87,
      0x1CD88, 0x1CD89, 0x1CD8A, 0x1CD8B, 0x1CD8C, 0x1CD8D, 0x1CD8E, 0x1CD8F,
      0x02597, 0x1CD90, 0x1CD91, 0x1CD92, 0x1CD93, 0x0259A, 0x1CD94, 0x1CD95,
      0x1CD96, 0x1CD97, 0x02590, 0x1CD98, 0x1CD99, 0x1CD9A, 0x1CD9B, 0x0259C,
      0x1CD9C, 0x1CD9D, 0x1CD9E, 0x1CD9F, 0x1CDA0, 0x1CDA1, 0x1CDA2, 0x1CDA3,
      0x1CDA4, 0x1CDA5, 0x1CDA6, 0x1CDA7, 0x1CDA8, 0x1CDA9, 0x1CDAA, 0x1CDAB,
      0x02582, 0x1CDAC, 0x1CDAD, 0x1CDAE, 0x1CDAF, 0x1CDB0, 0x1CDB1, 0x1CDB2,
      0x1CDB3, 0x1CDB4, 0x1CDB5, 0x1CDB6, 0x1CDB7, 0x1CDB8, 0x1CDB9, 0x1CDBA,
      0x1CDBB, 0x1CDBC, 0x1CDBD, 0x1CDBE, 0x1CDBF, 0x1CDC0, 0x1CDC1, 0x1CDC2,
      0x1CDC3, 0x1CDC4, 0x1CDC5, 0x1CDC6, 0x1CDC7, 0x1CDC8, 0x1CDC9, 0x1CDCA,
      0x1CDCB, 0x1CDCC, 0x1CDCD, 0x1CDCE, 0x1CDCF, 0x1CDD0, 0x1CDD1, 0x1CDD2,
      0x1CDD3, 0x1CDD4, 0x1CDD5, 0x1CDD6, 0x1CDD7, 0x1CDD8, 0x1CDD9, 0x1CDDA,
      0x02584, 0x1CDDB, 0x1CDDC, 0x1CDDD, 0x1CDDE, 0x02599, 0x1CDDF, 0x1CDE0,
      0x1CDE1, 0x1CDE2, 0x0259F, 0x1CDE3, 0x02586, 0x1CDE4, 0x1CDE5, 0x02588,
    ]

    def cell(bitmap : Bitmap, x : Int32, y : Int32) : Char
      CODEPOINTS[mask(bitmap, x, y)].chr
    end
  end

  # 2x4 pixels per cell using Braille Patterns. The dot numbering predates the
  # 8-dot form, so the first three rows fill the low bits column by column and
  # the fourth row lands in the two high bits.
  #
  # Empty cells are U+2800, not a space: the blank braille character keeps
  # columns aligned in terminals that render it at full cell width.
  struct Braille < Cell2x4
    BASE = 0x2800

    # Bit weight of each pixel, indexed by the row-major mask bit it comes from.
    DOTS = StaticArray[
      0x01, 0x08,
      0x02, 0x10,
      0x04, 0x20,
      0x40, 0x80,
    ]

    def cell(bitmap : Bitmap, x : Int32, y : Int32) : Char
      pattern = 0
      mask = mask(bitmap, x, y)

      DOTS.each_with_index do |dot, index|
        pattern |= dot if mask.bit(index) == 1
      end

      (BASE + pattern).chr
    end
  end

  # Declared last so the styles above are defined by the time they are built.
  ALL = {
    "half"    => Half.new.as(Style),
    "octant"  => Octant.new.as(Style),
    "braille" => Braille.new.as(Style),
  }

  DEFAULT = ALL["half"]

  def self.[]?(name : String) : Style?
    ALL[name]?
  end

  def self.[](name : String) : Style
    ALL[name]
  end

  def self.names : Array(String)
    ALL.keys
  end
end
