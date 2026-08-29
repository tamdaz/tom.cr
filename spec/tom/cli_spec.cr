require "../spec_helper"

describe Tom::CLI do
  describe ".parse_variants" do
    it "parses a single override" do
      Tom::CLI.parse_variants("S:2").should eq({'S' => 2})
    end

    it "parses a comma-separated list" do
      Tom::CLI.parse_variants("A:2,G:4").should eq({'A' => 2, 'G' => 4})
    end

    it "upcases the letter" do
      Tom::CLI.parse_variants("s:2").should eq({'S' => 2})
    end

    it "rejects malformed values" do
      ["S", "S:", ":2", "SS:2", "S:x", ""].each do |spec|
        expect_raises(ArgumentError) { Tom::CLI.parse_variants(spec) }
      end
    end
  end
end
