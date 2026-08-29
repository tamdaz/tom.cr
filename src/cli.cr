require "option_parser"
require "./normal"

module Tom::CLI
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

  # The banner shown above --help and usage errors: the project name rendered
  # in the block-octant style, standing in for a "." the font has no glyph for.
  def self.logo : String
    Fonts::Normal.render("TOM CR", style: Style["octant"])
  end

  def self.run(argv : Array(String)) : Nil
    style_name = "half"
    variant_overrides = {} of Char => Int32

    option_parser = OptionParser.new do |parser|
      parser.banner = "#{logo}\n\nUsage: tom [options] TEXT"

      parser.on("-s NAME", "--style=NAME", "Block characters to draw with: #{Style.names.join(", ")} (default: #{style_name})") do |name|
        style_name = name
      end

      parser.on("-v LETTER:N,...", "--variant=LETTER:N,...", "Use glyph variant N for a given letter, e.g. S:2 (repeatable)") do |spec|
        begin
          variant_overrides.merge!(parse_variants(spec))
        rescue ex : ArgumentError
          STDERR.puts ex.message
          exit(1)
        end
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end

      parser.invalid_option do |flag|
        STDERR.puts "Unknown option: #{flag}"
        STDERR.puts parser
        exit(1)
      end

      parser.missing_option do |flag|
        STDERR.puts "Missing value for #{flag}"
        STDERR.puts parser
        exit(1)
      end
    end

    option_parser.parse(argv)
    text = argv.join(' ')

    style = Style[style_name]?

    unless style
      STDERR.puts "Unknown style: #{style_name} (available: #{Style.names.join(", ")})"
      exit(1)
    end

    if text.empty?
      STDERR.puts option_parser
      exit(1)
    end

    variant_overrides.each do |letter, number|
      available = Fonts::Normal::VARIANTS[letter]?

      unless available && available.has_key?(number)
        STDERR.puts "Warning: no variant #{number} for #{letter.inspect}, using the default"
      end
    end

    puts Fonts::Normal.render(text, variant_overrides, style)
  end
end
