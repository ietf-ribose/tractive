module Tractive
  class Main
    def initialize(opts)
      @opts = opts
      @cfg  = YAML.load_file(@opts[:config])

      Tractive::Utilities.setup_logger(output_stream: STDERR, verbose: @opts[:verbose])
      @db = Tractive::Utilities.setup_db!(@cfg['trac']['database'])

    rescue Sequel::DatabaseConnectionError, Sequel::AdapterNotFound, URI::InvalidURIError, Sequel::DatabaseError => e
      $logger.error e.message
      exit 1
    end

    def run
      if @opts[:info]
        info
      elsif @opts[:attachmentexporter]
        create_attachment_exporter_script
      elsif @opts[:exportattachments]
        export_attachments
      else
        migrate
      end
    end

    def migrate
      Tractive::Migrator.new(opts: @opts, cfg: @cfg, db: @db).migrate
    end

    def info
      Tractive::Info.new(@db).print
    end

    def export_attachments
      Tractive::AttachmentExporter.new(@cfg, @db).export
    end

    def create_attachment_exporter_script
      Tractive::AttachmentExporter.new(@cfg, @db).generate_script
    end
  end
end
