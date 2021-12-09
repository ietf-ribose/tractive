# frozen_string_literal: true

require_relative "../lib/tractive"

class CommandBase < Thor
  class_option "logfile", type: :string, aliases: ["-L", "--log-file"],
                          desc: "Name of the logfile to output logs to."
  class_option "config", type: :string, default: "tractive.config.yaml", banner: "<PATH>", aliases: "-c",
                         desc: "Set the configuration file"
  class_option "verbose", type: :boolean, aliases: ["-v", "--verbose"], desc: "Verbose mode"
end
