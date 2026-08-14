require "option_parser"
require "./fonts/wide"
require "./fonts/compact"
require "./fonts/mini"

module Tom::CLI
  FONTS = {
    "wide"    => ->(text : String, style : Hash(Char, Int32)) { Fonts::Wide.render(text, style) },
    "compact" => ->(text : String, style : Hash(Char, Int32)) { Fonts::Compact.render(text, style) },
    "mini"    => ->(text : String, style : Hash(Char, Int32)) { Fonts::Mini.render(text, style) },
  }

  VARIANTS_BY_FONT = {
    "wide"    => Fonts::Wide::VARIANTS,
    "compact" => Fonts::Compact::VARIANTS,
    "mini"    => Fonts::Mini::VARIANTS,
  }

  # Parses a "LETTER:N,LETTER:N" list (as produced by one or more --variant
  # flags) into a Char => variant number override map.
  def self.parse_variants(spec : String) : Hash(Char, Int32)
    overrides = {} of Char => Int32

    spec.split(',').each do |pair|
      letter, sep, number = pair.partition(':')
      if sep.empty? || letter.size != 1 || number.empty? || !number.each_char.all?(&.ascii_number?)
        raise ArgumentError.new("Invalid --variant value #{pair.inspect} (expected LETTER:N, e.g. S:2)")
      end

      overrides[letter[0].upcase] = number.to_i
    end

    overrides
  end

  def self.run(argv : Array(String)) : Nil
    font_name = "wide"
    style = {} of Char => Int32

    option_parser = OptionParser.new do |parser|
      parser.banner = "Usage: tom [options] TEXT"

      parser.on("-f NAME", "--font=NAME", "Font to use: #{FONTS.keys.join(", ")} (default: #{font_name})") do |name|
        font_name = name
      end

      parser.on("-v LETTER:N,...", "--variant=LETTER:N,...", "Use glyph variant N for a given letter, e.g. S:2 (repeatable)") do |spec|
        begin
          style.merge!(parse_variants(spec))
        rescue ex : ArgumentError
          STDERR.puts ex.message
          exit(1)
        end
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    option_parser.parse(argv)
    text = argv.join(' ')

    render = FONTS[font_name]?
    unless render
      STDERR.puts "Unknown font: #{font_name} (available: #{FONTS.keys.join(", ")})"
      exit(1)
    end

    if text.empty?
      STDERR.puts "Missing text to render"
      STDERR.puts option_parser
      exit(1)
    end

    variants = VARIANTS_BY_FONT[font_name]
    style.each do |letter, number|
      available = variants[letter]?
      unless available && available.has_key?(number)
        STDERR.puts "Warning: font #{font_name.inspect} has no variant #{number} for #{letter.inspect}, using the default"
      end
    end

    puts render.call(text, style)
  end
end
