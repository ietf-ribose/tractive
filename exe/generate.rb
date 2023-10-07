# frozen_string_literal: true

require_relative "./command_base"

class Generate < CommandBase
  desc "revmap <OPTIONS>", "Generate a mapping from svn revision number to git sha hash."
  method_option "svnurl", type: :string, aliases: ["--svn-url"],
                          desc: "Svn url that should be used in revmap generation"
  method_option "svnlocalpath", type: :string, aliases: ["--svn-local-path"],
                                desc: "Local SVN repo path"
  method_option "gitlocalrepopath", type: :string, aliases: ["--git-local-repo-path"],
                                    desc: "Local git repo path that should be used in revmap generation"
  method_option "revtimestampfile", type: :string, aliases: ["--rev-timestamp-file"],
                                    desc: "File containing svn revision and timestamps that should be used in revmap generation"
  method_option "revoutputfile", type: :string, aliases: ["--revmap-output-file"],
                                 desc: "File to output the generated revmap"
  def revmap
    verify_revmap_generator_options!(options)

    Tractive::Utilities.setup_logger(output_stream: options[:log_file] || $stderr, verbose: options[:verbose])
    Tractive::RevmapGenerator.new(
      options["revtimestampfile"],
      options["svnurl"],
      options["svnlocalpath"],
      options["gitlocalrepopath"],
      options["revoutputfile"]
    ).generate
  end

  no_commands do
    def verify_revmap_generator_options!(options)
      required_options = {}
      required_options["--svn-url OR --svn-local-path"] = options["svnurl"] || options["svnlocalpath"]
      required_options["--git-local-repo-path"] = options["gitlocalrepopath"]
      required_options["--rev-timestamp-file"] = options["revtimestampfile"]
      required_options["--revmap-output-file"] = options["revoutputfile"]

      missing_options = {}
      required_options.each do |key, value|
        missing_options[key] = value if value.nil? || value.strip.empty?
      end

      return if missing_options.empty?

      warn("missing revmap generator options (#{missing_options.keys}).\nRun with `--help` or `-h` to see available options")
      exit 1
    end
  end
end
