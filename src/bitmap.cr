# A monochrome pixel grid, used as the pivot representation between the
# half-block glyph files on disk and the various render styles.
#
# Glyph data is authored in half blocks (one text cell encodes two vertical
# pixels), but octant and braille cells cover 2x4 pixels. Decoding to pixels
# first lets every style share one layout pass, so letter spacing stays the
# same width on screen whatever the cell size.
class Tom::Bitmap
  getter width : Int32
  getter height : Int32

  def initialize(@width : Int32, @height : Int32)
    @pixels = Array(Bool).new(@width * @height, false)
  end

  # Decodes half-block *rows* (as stored in the font data files) into pixels.
  # Rows shorter than the widest one are padded with blanks on the right.
  def self.from_half_blocks(rows : Array(String)) : Bitmap
    width = rows.max_of?(&.size) || 0
    bitmap = new(width, rows.size * 2)

    rows.each_with_index do |row, index|
      row.each_char_with_index do |char, x|
        bitmap[x, index * 2] = char == '▀' || char == '█'
        bitmap[x, index * 2 + 1] = char == '▄' || char == '█'
      end
    end

    bitmap
  end

  # Reads a pixel, treating anything outside the grid as unset so that
  # encoders can sample a whole cell without bounds checks of their own.
  def [](x : Int32, y : Int32) : Bool
    return false unless 0 <= x < @width && 0 <= y < @height

    @pixels[y * @width + x]
  end

  def []=(x : Int32, y : Int32, value : Bool) : Nil
    return unless 0 <= x < @width && 0 <= y < @height

    @pixels[y * @width + x] = value
  end

  # Copies *other* into this bitmap with its left edge at *x*, vertically
  # offset by *y*.
  def blit(other : Bitmap, x : Int32, y : Int32 = 0) : Nil
    other.height.times do |row|
      other.width.times do |column|
        self[x + column, y + row] = other[column, row]
      end
    end
  end

  # Returns a copy grown by *top* and *bottom* blank pixel rows.
  def pad_vertical(top : Int32, bottom : Int32) : Bitmap
    return self if top == 0 && bottom == 0

    padded = Bitmap.new(@width, @height + top + bottom)
    padded.blit(self, 0, top)
    padded
  end
end
