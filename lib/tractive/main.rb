# frozen_string_literal: true

module Tractive
  class Main
    def initialize(opts)
      verify_options!(opts)

      @opts = opts
      @cfg  = YAML.load_file(@opts[:config])

      Tractive::Utilities.setup_logger(output_stream: @opts[:logfile] || $stderr, verbose: @opts[:verbose])

      verify_config!(@cfg, @opts)

      @cfg["github"] ||= {}
      @cfg["github"]["token"] = @opts["git-token"] if @opts["git-token"]

      GithubApi::GraphQlClient.add_constants(@cfg["github"]["token"]) unless @opts[:info]

      @db = Tractive::Utilities.setup_db!(@opts["trac-database-path"] || @cfg["trac"]["database"])
    rescue Sequel::DatabaseConnectionError, Sequel::AdapterNotFound, URI::InvalidURIError, Sequel::DatabaseError => e
      $logger.error e.message
      exit 1
    rescue StandardError => e
      warn_and_exit(e.message, 1)
    end

    def run
      if @opts[:info]
        info
      elsif @opts[:attachmentexporter]
        create_attachment_exporter_script
      elsif @opts[:exportattachments]
        export_attachments
      elsif @opts[:generaterevmap]
        generate_revmap_file
      else
        migrate
      end
    end

    def migrate
      Migrator::Engine.new(opts: @opts, cfg: @cfg, db: @db).migrate
    end

    def migrate_wikis
      Migrator::Wikis::MigrateFromDb.new(opts: @opts, cfg: @cfg).migrate_wikis
    end

    def info
      Tractive::Info.new.print
    end

    def export_attachments
      Tractive::AttachmentExporter.new(@cfg, @db).export
    end

    def create_attachment_exporter_script
      Tractive::AttachmentExporter.new(@cfg, @db).generate_script
    end

    private

    def verify_config!(config, options)
      database_path_missing_error = <<~DATABASE_PATH_MISSING_ERROR
        Missing path for trac database which can be set using `--trac-database-path` or can
        be set in config file (see https://github.com/ietf-ribose/tractive#trac-configuration)
      DATABASE_PATH_MISSING_ERROR

      warn_and_exit(database_path_missing_error, 1) if !options["trac-database-path"] && !(config["trac"] && config["trac"]["database"])
    end

    def verify_options!(options)
      verify_config_options!(options)
      verify_filter_options!(options)
    end

    def verify_config_options!(options)
      return if File.exist?(options[:config])

      warn_and_exit("missing configuration file (#{options[:config]})", 1)
    end

    def verify_filter_options!(options)
      required_options = { columnname: "--column-name",
                           operator: "--operator",
                           columnvalue: "--column-value" }
      missing_options = {}
      required_options.each do |key, value|
        missing_options[key] = value if !options[key] || options[key].strip.empty?
      end

      return if !options[:filter] || missing_options.empty?

      warn_and_exit("missing filter options #{missing_options.values}", 1)
    end

    def warn_and_exit(message, exit_code)
      warn message
      warn "Run with `--help` or `-h` to see available options"
      exit exit_code
    end
  end
end
