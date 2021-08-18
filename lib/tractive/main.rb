module Tractive
  class Main
    class << self
      def run(opts)
        if opts[:info]
          new(opts).info
        else
          new(opts).migrate
        end
      end
    end

    def initialize(opts)
      @opts = opts
      @cfg  = YAML.load_file(@opts[:config])

      # Setup database.
      @db = setup_db(@cfg['trac']['database'])

      # Setup logger.
      $logger           = Logger.new(STDERR)
      $logger.level     = @opts[:verbose] ? Logger::DEBUG : Logger::INFO
      $logger.formatter = proc do |severity, datetime, progname, msg|
        time = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{time}] #{severity}#{' ' * (5 - severity.size + 1)}| #{msg}\n"
      end

      @revmap = load_revmap_file(@opts[:revmapfile])
      @trac = Tractive::Trac.new(@db)
    end

    def migrate
      if @opts[:attachmentexporter]
        begin
          trac.generate_attachment_exporter(@cfg)
        rescue StandardError => e
          $logger.error(e.message)
          exit(1)
        end
        exit(0)
      end

      # trac: trac, opts: opts, cfg: cfg, revmap: revmap

      # migrator = Migrator.new(
      #     trac, cfg['github'], cfg['users'], cfg['labels'], revmap,
      #     opts[:attachurl], opts[:singlepost], (not opts[:fast]), opts[:mockdeleted])

      migrator = Tractive::Migrator.new(trac: @trac, opts: @opts, cfg: @cfg, revmap: @revmap)
      migrator.migrate(@opts[:start], @opts[:openedonly])
    end

    def info
      @trac.info
    end

    def load_revmap_file(revmapfile = nil)
      # load revision mapping file and convert it to a hash.
      # This revmap file allows to map between SVN revisions (rXXXX)
      # and git commit sha1 hashes.
      revmap     = nil
      revmapfile ||= @cfg['revmapfile']
      if revmapfile
        File.open(revmapfile, "r:UTF-8") do |f|
          $logger.info("loading revision map #{revmapfile}")
          revmap = Hash[f.each_line
                            .map { |line| line.split(/\s+\|\s+/) }
                            .map { |rev, sha| [rev.gsub(/^r/, ''), sha] } # remove leading "r" if present
          ]
        end
      end

      revmap
    end

    def setup_db(db_url)
      db = Sequel.connect(db_url) if db_url

      if !db
        $logger.error('could not connect to trac databse')
        exit 1
      end

      Dir.glob('lib/tractive/model/*.rb') do |file|
        require_relative "../../#{file}"
      end

      db
    end
  end
end
