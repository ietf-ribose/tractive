# frozen_string_literal: true

module Migrator
  module Converter
    # twf => Trac wiki format
    class TwfToMarkdown
      def initialize(base_url, attachment_options, changeset_base_url, wiki_attachments_url, revmap_file_path, git_repo)
        @base_url = base_url
        @attach_url = attachment_options[:url]
        @attach_hashed = attachment_options[:hashed]
        @changeset_base_url = changeset_base_url
        @wiki_attachments_url = wiki_attachments_url
        @revmap = load_revmap_file(revmap_file_path)
        @git_repo = git_repo
      end

      def convert(str)
        convert_newlines(str)
        convert_comments(str)
        convert_html_snippets(str)
        convert_code_snippets(str)
        convert_headings(str)
        convert_image(str, @base_url, @attach_url, @wiki_attachments_url)
        convert_links(str, @git_repo)
        convert_font_styles(str)
        convert_changeset(str, @changeset_base_url)
        convert_ticket(str, @base_url)
        revert_intermediate_references(str)

        str
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
                      .map { |rev, sha| [rev.gsub(/^r/, ""), sha] }.to_h # remove leading "r" if present
          end
        end

        revmap
      end

      # Ticket
      def convert_ticket(str, base_url)
        # replace a full ticket id with the github short refrence
        if base_url
          baseurlpattern = base_url.gsub("/", "\\/")
          str.gsub!(%r{#{baseurlpattern}/(\d+)}, '#\1')
        end

        # Ticket
        str.gsub!(/ticket:(\d+)/, '#\1')
      end

      # Headings
      def convert_headings(str)
        str.gsub!(/======\s(.+?)\s======/, '###### \1')
        str.gsub!(/=====\s(.+?)\s=====/, '##### \1')
        str.gsub!(/====\s(.+?)\s====/, '#### \1')
        str.gsub!(/===\s(.+?)\s===/, '### \1')
        str.gsub!(/==\s(.+?)\s==/, '## \1')
        str.gsub!(/=\s(.+?)\s=/, '# \1')
      end

      # Line endings
      def convert_newlines(str)
        str.gsub!(/\[\[br\]\]/i, "\n")
        str.gsub!("\r\n", "\n")
      end

      # Comments
      def convert_comments(str)
        str.gsub!(/\{\{\{#!comment([\s|\n])(.*?)\}\}\}/m, '<!--\1\2\1-->')
      end

      # HTML Snippets
      def convert_html_snippets(str)
        str.gsub!(/\{\{\{#!html(.*?)\}\}\}/m, '\1')
      end

      # CommitTicketReference
      def convert_ticket_reference(str)
        str.gsub!(/\{\{\{\n(#!CommitTicketReference .+?)\}\}\}/m, '\1')
        str.gsub!(/#!CommitTicketReference .+\n/, "")
      end

      # Code
      def convert_code_snippets(str)
        str.gsub!(/\{\{\{([^\n]+?)\}\}\}/, '`\1`')
        str.gsub!(/\{\{\{#!(.*?)\n(.+?)\}\}\}/m, "```\\1\n\\2\n```")
        str.gsub!(/\{\{\{(.+?)\}\}\}/m, '```\1```')
        str.gsub!(/(?<=```)#!/m, "")
      end

      # Changeset
      def convert_changeset(str, changeset_base_url)
        str.gsub!(%r{#{Regexp.quote(changeset_base_url)}/(\d+)/?}, '[changeset:\1]') if changeset_base_url
        str.gsub!(/\[changeset:"r(\d+)".*\]/, '[changeset:\1]')
        str.gsub!(/\[changeset:r(\d+)\]/, '[changeset:\1]')
        str.gsub!(/\br(\d+)\b/) { Tractive::Utilities.map_changeset(Regexp.last_match[1], @revmap, changeset_base_url) }
        str.gsub!(/\[changeset:"(\d+)".*\]/) { Tractive::Utilities.map_changeset(Regexp.last_match[1], @revmap, changeset_base_url) }
        str.gsub!(/\[changeset:(\d+).*\]/) { Tractive::Utilities.map_changeset(Regexp.last_match[1], @revmap, changeset_base_url) }
        str.gsub!(/\[(\d+)\]/) { Tractive::Utilities.map_changeset(Regexp.last_match[1], @revmap, changeset_base_url) }
        str.gsub!(%r{\[(\d+)/.*\]}) { Tractive::Utilities.map_changeset(Regexp.last_match[1], @revmap, changeset_base_url) }
      end

      # Font styles
      def convert_font_styles(str)
        str.gsub!(/'''(.+?)'''/, '**\1**')
        str.gsub!(/''(.+?)''/, '*\1*')
        str.gsub!(%r{([^:])//(.+?[^:])//}, '\1_\2_')
      end

      # Links
      def convert_links(str, git_repo)
        convert_camel_case_links(str, git_repo)
        convert_double_bracket_wiki_links(str, git_repo)
        convert_single_bracket_wiki_links(str, git_repo)

        str.gsub!(/\[(http[^\s\[\]]+)\s([^\[\]]+)\]/, '[\2](\1)')
        str.gsub!(/!(([A-Z][a-z0-9]+){2,})/, '\1')
      end

      def convert_single_bracket_wiki_links(str, git_repo)
        str.gsub!(/\[(wiki:)?([^\s]*) ?(.*?)\]/) do
          wiki = Regexp.last_match[1]
          path = Regexp.last_match[2]
          name = Regexp.last_match[3]

          if wiki
            "{{#{name}}}(https://github.com/#{git_repo}/wiki/#{name})"
          elsif path.start_with?("http")
            name = path if name.empty?
            "{{#{name}}}(#{path})"
          else
            "[#{path}]"
          end
        end
      end

      def convert_double_bracket_wiki_links(str, git_repo)
        str.gsub!(/(!?)\[\[(wiki:)?([^|\n]*)\|?(.*)\]\]/) do |match_result|
          wiki = Regexp.last_match[2]
          path = Regexp.last_match[3]
          name = Regexp.last_match[4]

          if Regexp.last_match[1] == "!"
            match_result
          elsif wiki
            "{{#{name}}}(https://github.com/#{git_repo}/wiki/#{name})"
          elsif path.start_with?("http")
            name = path if name.empty?
            "{{#{name}}}(#{path})"
          else
            "[#{path}]"
          end
        end
      end

      # CamelCase page names follow these rules:
      #   1. The name must consist of alphabetic characters only;
      #      no digits, spaces, punctuation or underscores are allowed.
      #   2. A name must have at least two capital letters.
      #   3. The first character must be capitalized.
      #   4. Every capital letter must be followed by one or more lower-case letters.
      #   5. The use of slash ( / ) is permitted in page names, where it typically represents a hierarchy.
      def convert_camel_case_links(str, git_repo)
        name_regex = %r{(^| )(!?)(/?[A-Z][a-z]+(/?[A-Z][a-z]+)+/?)}
        wiki_pages_names = Tractive::Wiki.select(:name).distinct.map(:name)
        str.gsub!(name_regex) do
          start = Regexp.last_match[2]
          name = Regexp.last_match[3]

          wiki_link = if start != "!" && wiki_pages_names.include?(name)
                        make_wiki_link(name, git_repo)
                      else
                        name
                      end

          "#{Regexp.last_match[1]}#{wiki_link}"
        end
      end

      def make_wiki_link(wiki_name, git_repo)
        "[#{wiki_name}](https://github.com/#{git_repo}/wiki/#{wiki_name})"
      end

      def convert_image(str, base_url, attach_url, wiki_attachments_url)
        # https://trac.edgewall.org/wiki/WikiFormatting#Images
        # [[Image(picture.gif)]] Current page (Ticket, Wiki, Comment)
        # [[Image(wiki:WikiFormatting:picture.gif)]] (referring to attachment on another page)
        # [[Image(ticket:1:picture.gif)]] (file attached to a ticket)

        image_regex = /\[\[Image\((?:(?<module>(?:source|wiki)):)?(?<path>[^)]+)\)\]\]/

        str.gsub!(image_regex) do
          path = Regexp.last_match[:path]
          mod = Regexp.last_match[:module]

          converted_image = if mod == "source"
                              "!{{#{path.split("/").last}}}(#{base_url}#{path})"
                            elsif mod == "wiki"
                              id, file = path.split(":")
                              upload_path = "#{wiki_attachments_url}/#{Tractive::Utilities.attachment_path(id, file, hashed: @attach_hashed)}"
                              "!{{#{file}}}(#{upload_path})"
                            elsif path.start_with?("http")
                              # [[Image(http://example.org/s.jpg)]]
                              "!{{#{path}}}(#{path})"
                            else
                              _, id, file = path.split(":")
                              file_path = "#{attach_url}/#{Tractive::Utilities.attachment_path(id, file, hashed: @attach_hashed)}"
                              "!{{#{path}}}(#{file_path})"
                            end

          # There are also ticket references in the format of ticket:1 so
          # changing this now and will revert it at the end again
          converted_image.gsub(/ticket:(\d+)/, 'ImageTicket~\1')
        end
      end

      def revert_intermediate_references(str)
        str.gsub!(/ImageTicket~(\d)/, 'ticket:\1')
        str.gsub!("{{", "[")
        str.gsub!("}}", "]")
      end
    end
  end
end
