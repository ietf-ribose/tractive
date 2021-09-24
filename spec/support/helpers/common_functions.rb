# frozen_string_literal: true

module Helpers
  module CommonFunctions
    def options_for_migrator(options = {})
      {
        opts: options,
        cfg: CONFIG,
        db: @db
      }
    end

    def options_for_markdown_converter(options = {})
      {
        base_url: options[:base_url] || "https://foo.bar/trac/foobar/ticket",
        attach_url: options[:attach_url] || "https://foo.bar/trac/attachments",
        changeset_base_url: options[:changeset_base_url] || "https://foo.bar/trac/changeset",
        wiki_attachments_url: options[:wiki_attachments_url] || "https://foo.bar/wiki/attachments"
      }
    end

    # TODO: Need to remove this when refactoring migrator class
    def format_time(time)
      time = Time.at(time / 1e6, time % 1e6)
      time.strftime("%FT%TZ")
    end
  end
end
