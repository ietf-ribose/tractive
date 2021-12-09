# frozen_string_literal: true

require "csv"

module Migrator
  module Wikis
    class MigrateFromDb
      def initialize(args)
        $logger.debug("OPTIONS = #{args}")

        @config = args[:cfg]
        @options = args[:opts]
        @authors_map = @config["users"].to_h

        @tracticketbaseurl    = @config["trac"]["ticketbaseurl"]
        @changeset_base_url   = @config["trac"]["changeset_base_url"] || ""
        @wiki_attachments_url = @options["attachment-base-url"] || @config.dig("wiki", "attachments", "url") || ""
        @repo_path            = @options["repo-path"] || ""
        @revmap_path          = @config["revmap_path"]

        @attachment_options   = {
          hashed: @config.dig("ticket", "attachments", "hashed")
        }

        verify_options
        verify_locations

        @twf_to_markdown = Migrator::Converter::TwfToMarkdown.new(@tracticketbaseurl, @attachment_options, @changeset_base_url, @wiki_attachments_url, @revmap_path)
      end

      def migrate_wikis
        $logger.info("Processing the wiki...")

        Dir.chdir(@options["repo-path"]) do
          # For every version of every file in the wiki...
          Tractive::Wiki.for_migration.each do |wiki|
            next if skip_file(wiki[:name])

            comment = if wiki[:comment].nil? || wiki[:comment].empty?
                        "Initial load of version #{wiki[:version]} of trac-file #{wiki[:name]}"
                      else
                        wiki[:comment].gsub('"', '\"')
                      end

            file_name = "#{cleanse_filename(wiki[:name])}.md"
            $logger.info("Working with file [#{file_name}]")
            $logger.debug("Object: #{wiki}")

            wiki_markdown_text = @twf_to_markdown.convert(wiki[:text])

            # Create file with content
            File.open(file_name, "w") do |f|
              f.puts(wiki_markdown_text)
            end

            # git-add it
            unless execute_command("git add #{file_name}").success?
              $logger.error("ERROR at git-add #{file_name}!!!")
              exit(1)
            end

            author = generate_author(wiki[:author])

            # git-commit it
            commit_command = "git commit --allow-empty -m \"#{comment}\" --author \"#{author}\" --date \"#{wiki[:fixeddate]}\""
            unless execute_command(commit_command).success?
              $logger.error("ERROR at git-commit #{file_name}!!!")
              exit(1)
            end
          end
        end
      end

      private

      def verify_options
        $logger.info("Verifying options...")

        missing_options = []
        missing_options << "attachment-base-url" if @wiki_attachments_url.empty?
        missing_options << "repo-path" if @repo_path.empty?

        return if missing_options.empty?

        $logger.error("Following options are missing: #{missing_options} - exiting...")
        exit(1)
      end

      def verify_locations
        $logger.info("Verifying locations...")
        missing_directories = []

        # git-root exists?
        missing_directories << "repo-path" unless Dir.exist?(@repo_path)

        return if missing_directories.empty?

        $logger.error("Following directories are missing: #{missing_directories} - exiting ...")
        exit(1)
      end

      def cleanse_filename(name)
        # Get rid of 'magic' characters from potential filename - replace with '_'
        # Magic: [ /<>- ]
        name.gsub(%r{[/<>-]}, "_")
      end

      def skip_file(file_name)
        file_name.start_with?("Trac") || (file_name.start_with?("Wiki") && !file_name.start_with?("WikiStart"))
      end

      def generate_author(author)
        return "" if author.nil? || author.empty?

        author_name = @authors_map[author]&.[]("name") || author.split("@").first
        author_email = @authors_map[author]&.[]("email") || author

        "#{author_name} <#{author_email}>"
      end

      def execute_command(command)
        `#{command}`
        $CHILD_STATUS
      end
    end
  end
end
