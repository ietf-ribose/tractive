# frozen_string_literal: true

module Tractive
  class Utilities
    class << self
      def make_hash(prefix, array)
        array.map { |i| [i, "#{prefix}#{i}"] }.to_h
      end

      def make_each_hash(values, keys)
        values.map do |value|
          value = [value] unless value.is_a?(Array)
          [value[0], keys.zip(value).to_h]
        end.to_h
      end

      def setup_db!(db_url)
        files_to_load = [
          "lib/tractive/models/attachment.rb",
          "lib/tractive/models/milestone.rb",
          "lib/tractive/models/report.rb",
          "lib/tractive/models/revision.rb",
          "lib/tractive/models/session.rb",
          "lib/tractive/models/ticket_change.rb",
          "lib/tractive/models/ticket.rb"
        ]
        db = Sequel.connect(db_url) if db_url

        raise("could not connect to tractive database") unless db

        files_to_load.each do |file|
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

      # returns the git commit hash for a specified revision (using revmap hash)
      def map_changeset(str, revmap, changeset_base_url = "")
        if revmap&.key?(str)
          base_url = changeset_base_url
          base_url += "/" if base_url[-1] && base_url[-1] != "/"
          "#{base_url}#{revmap[str].strip}"
        else
          "[#{str}]"
        end
      end

      def svn_log(url, local_path, flags = {})
        command = "svn log"
        command += " #{url}" if url

        flags.each do |key, value|
          command += " #{key}"
          command += " #{value}" if value
        end

        if local_path
          Dir.chdir(local_path) do
            `#{command}`
          end
        else
          `#{command}`
        end
      end
    end
  end
end
