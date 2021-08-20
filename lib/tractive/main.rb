module Tractive
  class Main
    def initialize(opts)
      @opts = opts
      @cfg  = YAML.load_file(@opts[:config])

      Tractive::Utilities.setup_logger(output_stream: STDERR, verbose: @opts[:verbose])

      @db = Tractive::Utilities.setup_db!(@cfg['trac']['database'])

      @trac = Tractive::Trac.new(@db)
    rescue Sequel::DatabaseConnectionError, Sequel::AdapterNotFound, URI::InvalidURIError, Sequel::DatabaseError => e
      $logger.error e.message
      exit 1
    end

    def run
      if @opts[:info]
        info
      elsif @opts[:attachmentexporter]
        export_attachments
      else
        migrate
      end
    end

    def migrate
      Tractive::Migrator.new(trac: @trac, opts: @opts, cfg: @cfg).migrate
    end

    def info
      Tractive::Info.new(@db).print
    end

    def export_attachments
      @trac.generate_attachment_exporter(@cfg)
    end
  end
end
