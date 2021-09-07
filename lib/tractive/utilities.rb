# frozen_string_literal: true

module Tractive
  class Utilities
    class << self
      def make_hash(prefix, array)
        array.map { |i| [i, "#{prefix}#{i}"] }.to_h
      end

      def setup_db!(db_url)
        db = Sequel.connect(db_url) if db_url

        raise("could not connect to tractive databse") unless db

        Dir.glob("lib/tractive/models/*.rb") do |file|
          require_relative "../../#{file}"
        end

        db
      end

      def setup_logger(options = {})
        $logger           = Logger.new(options[:output_stream])
        $logger.level     = options[:verbose] ? Logger::DEBUG : Logger::INFO
        $logger.formatter = proc do |severity, datetime, _progname, msg|
          time = datetime.strftime("%Y-%m-%d %H:%M:%S")
          "[#{time}] #{severity}#{" " * (5 - severity.size + 1)}| #{msg}\n"
        end
      end
    end
  end
end
