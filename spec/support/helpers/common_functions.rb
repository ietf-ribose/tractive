# frozen_string_literal: false

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
        attachment_options: { url: options[:attach_url] || "https://foo.bar/trac/attachments", hashed: false },
        changeset_base_url: options[:changeset_base_url] || "https://github.com/repo/commits",
        wiki_attachments_url: options[:wiki_attachments_url] || "https://foo.bar/wiki/attachments",
        revmap_file_path: options[:revmap_file_path] || "spec/files/revmap_spec.txt",
        options: { git_repo: options[:git_repo] || "foo/bar", home_page_name: "WikiStart" }
      }
    end

    def test_comments
      [
        { "url" => "https://api.github.com/repos/test/repo/issues/comments/913628459",
          "html_url" => "https://github.com/test/repo/issues/1#issuecomment-913628459",
          "issue_url" => "https://api.github.com/repos/test/repo/issues/1",
          "id" => 913_628_459,
          "body" => "_@hassanakbar4_ _commented_\n\n\n___\n2.5 hours for proceedings model\n8 hours for iddb work\n2-3 hours for other model work over the weekend" },
        { "url" => "https://api.github.com/repos/test/repo/issues/comments/913628463",
          "html_url" => "https://github.com/test/repo/issues/1#issuecomment-913628463",
          "issue_url" => "https://api.github.com/repos/test/repo/issues/1",
          "id" => 913_628_463,
          "body" => "_@hassanakbar4_ _changed status from `new` to `closed`_" },
        { "url" => "https://api.github.com/repos/test/repo/issues/comments/913628465",
          "html_url" => "https://github.com/test/repo/issues/1#issuecomment-913628465",
          "issue_url" => "https://api.github.com/repos/test/repo/issues/1",
          "id" => 913_628_465,
          "body" => "_@hassanakbar4_ _changed resolution from `` to `fixed`_" },
        { "url" => "https://api.github.com/repos/test/repo/issues/comments/913628467",
          "html_url" => "https://github.com/test/repo/issues/1#issuecomment-913628467",
          "issue_url" => "https://api.github.com/repos/test/repo/issues/1",
          "id" => 913_628_467,
          "body" => "_@hassanakbar4_ _commented_\n\n\n___\nReplying to [comment:1 abc@gmail.com]:" }
      ]
    end

    # TODO: Need to remove this when refactoring migrator class
    def format_time(time)
      time = Time.at(time / 1e6, time % 1e6)
      time.strftime("%FT%TZ")
    end
  end
end
