# frozen_string_literal: true

require_relative "engine/migrate_from_db"
require_relative "engine/migrate_from_file"
require_relative "engine/migrate_to_file"

require_relative "converter/trac_to_github"
require_relative "converter/rtf_to_markdown"

# Service to perform migrations
module Migrator
  class Engine
    include Migrator::Engine::MigrateFromDb
    include Migrator::Engine::MigrateToFile
    include Migrator::Engine::MigrateFromFile

    def initialize(args)
      # def initialize(trac, github, users, labels, revmap, attachurl, singlepost, safetychecks, mockdeleted = false)
      @config = args

      db                = args[:db]
      github            = args[:cfg]["github"]
      safetychecks      = !(args[:opts][:fast])
      mockdeleted       = args[:opts][:mockdeleted]
      start_ticket      = args[:opts][:start]
      filter_closed     = args[:opts][:openedonly]
      input_file_name   = args[:opts][:importfromfile]

      @filter_applied   = args[:opts][:filter]
      @filter_options   = { column_name: args[:opts][:columnname], operator: args[:opts][:operator], column_value: args[:opts][:columnvalue] }

      @trac  = Tractive::Trac.new(db)
      @repo  = github["repo"]
      @client = GithubApi::Client.new(access_token: github["token"])

      if input_file_name
        @from_file = input_file_name
        file = File.open(@from_file, "r")
        @input_file = JSON.parse(file.read)
        file.close
      end

      @ticket_to_issue   = {}
      @mockdeleted       = mockdeleted || @filter_applied

      $logger.debug("Get highest in #{@repo}")
      issues = @client.issues(@repo, { filter: "all",
                                       state: "all",
                                       sort: "created",
                                       direction: "desc" })

      @last_created_issue = issues.empty? ? 0 : issues[0]["number"].to_i

      $logger.info("created issue on GitHub is '#{@last_created_issue}' #{issues.count}")

      dry_run_output_file = args[:cfg][:dry_run_output_file] || "#{Dir.pwd}/dryrun_out.json"

      @dry_run          = args[:opts][:dryrun]
      @output_file      = File.new(dry_run_output_file, "w+")
      @delimiter        = "{"
      @revmap           = load_revmap_file(args[:opts][:revmapfile] || args[:cfg]["revmapfile"])
      @safetychecks     = safetychecks
      @start_ticket     = (start_ticket || (@last_created_issue + 1)).to_i
      @filter_closed    = filter_closed
      @uri_parser = URI::Parser.new
    end

    def migrate
      if @dry_run
        migrate_to_file
      elsif @from_file
        migrate_from_file
      else
        migrate_from_db
      end
    end

    private

    def load_revmap_file(revmapfile)
      # load revision mapping file and convert it to a hash.
      # This revmap file allows to map between SVN revisions (rXXXX)
      # and git commit sha1 hashes.
      revmap = nil
      if revmapfile
        File.open(revmapfile, "r:UTF-8") do |f|
          $logger.info("loading revision map #{revmapfile}")

          revmap = f.each_line
                    .map { |line| line.split(/\s+\|\s+/) }
                    .map { |rev, sha, _| [rev.gsub(/^r/, ""), sha] }.to_h # remove leading "r" if present
        end
      end

      revmap
    end

    def mock_ticket_details(ticket_id)
      summary = if @filter_applied
                  "Not available in trac #{ticket_id}"
                else
                  "DELETED in trac #{ticket_id}"
                end
      {
        id: ticket_id,
        summary: summary,
        time: Time.now.to_i,
        status: "closed",
        reporter: "tractive"
      }
    end
  end
end
