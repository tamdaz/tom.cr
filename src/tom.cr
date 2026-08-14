require "./tom/cli"

module Tom
  VERSION = {{ `shards version`.stringify }}
end

Tom::CLI.run(ARGV)
