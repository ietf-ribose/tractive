# frozen_string_literal: true

module Tractive
  class MarkdownConverter
    def initialize(base_url, attach_url, ticket_id)
      @ticketbaseurl = base_url
      @attachurl = attach_url
      @current_ticket_id = ticket_id
    end

    def self.convert(str, base_url, attach_url, ticket_id)
      new(base_url, attach_url, ticket_id).convert(str)
    end

    def convert(str)
      convert_newlines(str)
      convert_code_snippets(str)
      convert_headings(str)
      convert_links(str)
      convert_font_styles(str)
      convert_lists(str)
      convert_changeset(str)
      convert_image(str)
      convert_ticket(str)

      str
    end

    private

    # CommitTicketReference
    def convert_ticket_reference(str)
      str.gsub!(/\{\{\{\n(#!CommitTicketReference .+?)\}\}\}/m, '\1')
      str.gsub!(/#!CommitTicketReference .+\n/, "")
    end

    # Ticket
    def convert_ticket(str)
      # replace a full ticket id with the github short refrence
      if @ticketbaseurl
        baseurlpattern = @ticketbaseurl.gsub("/", "\\/")
        str.gsub!(%r{#{baseurlpattern}/(\d+)}) { "ticket:#{Regexp.last_match[1]}  " }
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

    # Code
    def convert_code_snippets(str)
      str.gsub!(/\{\{\{([^\n]+?)\}\}\}/, '`\1`')
      str.gsub!(/\{\{\{(.+?)\}\}\}/m, '```\1```')
      str.gsub!(/(?<=```)#!/m, "")
    end

    # Changeset
    def convert_changeset(str)
      str.gsub!(%r{https?://svnweb.cern.ch/trac/madx/changeset/(\d+)/?}, '[changeset:\1]')
      str.gsub!(/\[changeset:"r(\d+)".*\]/, '[changeset:\1]')
      str.gsub!(/\[changeset:r(\d+)\]/, '[changeset:\1]')
      str.gsub!(/\br(\d+)\b/) { Tractive::Utilities.map_changeset(Regexp.last_match[1]) }
      str.gsub!(/\[changeset:"(\d+)".*\]/) { Tractive::Utilities.map_changeset(Regexp.last_match[1]) }
      str.gsub!(/\[changeset:"(\d+).*\]/) { Tractive::Utilities.map_changeset(Regexp.last_match[1]) }
    end

    # Lists
    def convert_lists(str)
      str.gsub!(/(^\s+)\*/, '\1-')
      str.gsub!(/(^\s+)(\d)\./, '\1\2.')
    end

    # Font styles
    def convert_font_styles(str)
      str.gsub!(/'''(.+?)'''/, '**\1**')
      str.gsub!(/''(.+?)''/, '*\1*')
      str.gsub!(%r{[^:]//(.+?[^:])//}, '_\1_')
    end

    # Links
    def convert_links(str)
      str.gsub!(/\[(http[^\s\[\]]+)\s([^\[\]]+)\]/, '[\2](\1)')
      str.gsub!(/!(([A-Z][a-z0-9]+){2,})/, '\1')
    end

    def convert_image(str)
      # https://trac.edgewall.org/wiki/WikiFormatting#Images
      # [[Image(picture.gif)]] Current page (Ticket, Wiki, Comment)
      # [[Image(wiki:WikiFormatting:picture.gif)]] (referring to attachment on another page)
      # [[Image(ticket:1:picture.gif)]] (file attached to a ticket)

      d = /\[\[Image\((?:(?<module>(?:source|wiki)):)?(?<path>[^)]+)\)\]\]/.match(str)
      return if d.nil?

      path = d[:path]
      mod = d[:module]

      if mod == "source"
        "![](#{@ticketbaseurl}/#{path})"
      elsif mod == "wiki"
        d[:upload_path] = "/uploads/migrated/#{file}"
        "![#{file}](#{d[:upload_path]})"
      elsif path.start_with?("http")
        # [[Image(http://example.org/s.jpg)]]
        "![#{d[:path]}](#{d[:path]})"
      else
        _, id, file = path.split(":")
        file_path = "#{@attachurl}/#{id}/#{file}"
        "![#{d[:path]}](#{file_path})"
      end
    end
  end
end
