# frozen_string_literal: false

RSpec.describe Migrator::Converter::TwfToMarkdown do
  let(:twf_to_markdown) { Migrator::Converter::TwfToMarkdown.new(*options_for_markdown_converter.values) }

  describe "#convert_changeset" do
    it "should convert changesets" do
      stub_issues_request
      stub_milestone_map_request
      stub_milestone_request

      str1 = "Fixed in [1234]"
      str2 = "Fixed in [1234567]"
      str3 = "Fixed in [1234/mailarch]"

      twf_to_markdown.send(:convert_changeset, str1, options_for_markdown_converter[:changeset_base_url])
      twf_to_markdown.send(:convert_changeset, str2, options_for_markdown_converter[:changeset_base_url])
      twf_to_markdown.send(:convert_changeset, str3, options_for_markdown_converter[:changeset_base_url])

      expect(str1).to eq("Fixed in https://github.com/repo/commits/abcd123")
      expect(str2).to eq("Fixed in [1234567]")
      expect(str3).to eq("Fixed in https://github.com/repo/commits/abcd123")
    end
  end

  describe "#convert_ticket" do
    it "should convert ticket base url" do
      str = "https://foo.bar/trac/foobar/ticket/123"

      twf_to_markdown.send(:convert_ticket, str, options_for_markdown_converter[:base_url])

      expect(str).to eq("#123")
    end

    it "should convert ticket reference" do
      str = "ticket:123"

      twf_to_markdown.send(:convert_ticket, str, options_for_markdown_converter[:base_url])

      expect(str).to eq("#123")
    end
  end

  describe "#convert_tables" do
    it "should convert tables" do
      str = "|| col1 || col2 ||\n|| r1 || r2 ||"
      twf_to_markdown.send(:convert_tables, str)

      expect(str).to eq("| col1 | col2 |\n| --- | --- |\n| r1 | r2 |\n")
    end
  end

  describe "#convert_headings" do
    it "should convet headings properly" do
      str  = "= h1 = \n"
      str += "== h2 == \n"
      str += "=== h3 === \n"
      str += "==== h4 ==== \n"
      str += "===== h5 ===== \n"
      str += "====== h6 ====== \n"

      twf_to_markdown.send(:convert_headings, str)

      expect(str).to eq("# h1 \n## h2 \n### h3 \n#### h4 \n##### h5 \n###### h6 \n")
    end
  end

  describe "#convert_newlines" do
    it "should convert line endings" do
      str = "foo [[br]] bar \r\n baz [[BR]]"

      twf_to_markdown.send(:convert_newlines, str)

      expect(str).to eq("foo \n bar \n baz \n")
    end
  end

  describe "#convert_comments" do
    it "should convert comments" do
      str1 = "{{{#!comment this is a comment}}}"
      str2 = <<~WIKI_COMMENT_TEXT
        {{{#!comment
        this is a comment
        }}}
      WIKI_COMMENT_TEXT

      twf_to_markdown.send(:convert_comments, str1)
      twf_to_markdown.send(:convert_comments, str2)

      expect(str1).to eq("<!-- this is a comment -->")
      expect(str2).to eq("<!--\nthis is a comment\n\n-->\n")
    end
  end

  describe "#convert_html_snippets" do
    it "should convert html snippets" do
      str = <<~WIKI_HTML_SNIPPET
        {{{#!html
        <h1 style="text-align: right; color: blue">
          HTML Test
        </h1>
        }}}
      WIKI_HTML_SNIPPET

      expected_str = <<~MARKDOWN_HTML_SNIPPET

        <h1 style="text-align: right; color: blue">
          HTML Test
        </h1>

      MARKDOWN_HTML_SNIPPET

      twf_to_markdown.send(:convert_html_snippets, str)

      expect(str).to eq(expected_str)
    end
  end

  describe "#convert_code_snippets" do
    it "should convert code snippets" do
      str = <<~WIKI_CODE_SNIPPET
        {{{single line code}}}

        {{{
        multiline
        code
        }}}

        {{{#!ruby
        def foo
          puts "hello world"
        end
        }}}

        {{{#!python
        def foo
          puts "hello world"
        end
        }}}
      WIKI_CODE_SNIPPET

      expected_str = <<~MARKDOWN_CODE_SNIPPET
        `single line code`

        ```
        multiline
        code
        ```

        ```ruby
        def foo
          puts "hello world"
        end

        ```

        ```python
        def foo
          puts "hello world"
        end

        ```
      MARKDOWN_CODE_SNIPPET

      twf_to_markdown.send(:convert_code_snippets, str)

      expect(str).to eq(expected_str)
    end
  end

  describe "#convert_font_styles" do
    it "should convert font styles" do
      bold = "'''bold'''"
      italic = "''italic'' //italic//"

      twf_to_markdown.send(:convert_font_styles, bold)
      twf_to_markdown.send(:convert_font_styles, italic)

      expect(bold).to eq("**bold**")
      expect(italic).to eq("*italic* _italic_")
    end
  end

  describe "#convert_links" do
    it "should convert links in CamelCase" do
      str = <<~LINKS
        HelloWorld
        UrlDesign
        badUrlDesign
        good ProjectSetup
      LINKS

      expected_str = <<~CONVERTED_LINKS
        HelloWorld
        [UrlDesign](https://github.com/#{options_for_markdown_converter[:git_repo]}/wiki/UrlDesign)
        badUrlDesign
        good [ProjectSetup](https://github.com/#{options_for_markdown_converter[:git_repo]}/wiki/ProjectSetup)
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end

    it "should convert links in single square bracket" do
      str = <<~LINKS
        [https://www.google.com google single]
        [comment:3 fenner@research.att.com]
        [wiki:WikiStart#CodeSprints Code Sprints]
        Link in the middle [https://www.google.com Google] of line
        [https://www.google.com]
        Link without name in [https://www.google.com] middle of line.
        Multiple links [https://www.google.com one] in one [https://www.facebook.com facebook two] line.
      LINKS

      expected_str = <<~CONVERTED_LINKS
        [google single](https://www.google.com)
        [comment:3 fenner@research.att.com]
        [Code Sprints](https://github.com/foo/bar/wiki/WikiStart#code-sprints)
        Link in the middle [Google](https://www.google.com) of line
        [https://www.google.com](https://www.google.com)
        Link without name in [https://www.google.com](https://www.google.com) middle of line.
        Multiple links [one](https://www.google.com) in one [facebook two](https://www.facebook.com) line.
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end

    it "should convert links in double square bracket" do
      str = <<~LINKS
        [[https://www.google.com|google double]]
        Link in the middle [[https://www.google.com|Google]] of line
        [[https://www.google.com]]
        Link without name in [[https://www.google.com]] middle of line.
        Multiple links [[https://www.google.com|one]] in one [[https://www.facebook.com|facebook two]] line.
      LINKS

      expected_str = <<~CONVERTED_LINKS
        [google double](https://www.google.com)
        Link in the middle [Google](https://www.google.com) of line
        [https://www.google.com](https://www.google.com)
        Link without name in [https://www.google.com](https://www.google.com) middle of line.
        Multiple links [one](https://www.google.com) in one [facebook two](https://www.facebook.com) line.
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end

    it "should not convert links starting with `!`" do
      str = <<~LINKS
        !UrlDesign !ProjectSetup
        Don't make link in middle ![https://www.google.com google single] of the line.
      LINKS

      expected_str = <<~CONVERTED_LINKS
        UrlDesign ProjectSetup
        Don't make link in middle [https://www.google.com google single] of the line.
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end
  end

  describe "#convert_image" do
    it "should convert image" do
      img1 = "This is an image [[Image(https://google/image/1)]]"
      img2 = "[[Image(ticket:1:picture.png)]]"
      img3 = "[[Image(wiki:WikiFormatting:picture.png)]]"
      img4 = "[[Image(source:/trunk/trac/htdocs/trac_logo_mini.png)]]"

      base_url = options_for_markdown_converter[:base_url]
      attach_url = options_for_markdown_converter[:attachment_options][:url]
      wiki_attachments_url = options_for_markdown_converter[:wiki_attachments_url]

      twf_to_markdown.send(:convert_image, img1, base_url, attach_url, wiki_attachments_url)
      twf_to_markdown.send(:convert_image, img2, base_url, attach_url, wiki_attachments_url)
      twf_to_markdown.send(:convert_image, img3, base_url, attach_url, wiki_attachments_url)
      twf_to_markdown.send(:convert_image, img4, base_url, attach_url, wiki_attachments_url)

      twf_to_markdown.send(:revert_intermediate_references, img1)
      twf_to_markdown.send(:revert_intermediate_references, img2)
      twf_to_markdown.send(:revert_intermediate_references, img3)
      twf_to_markdown.send(:revert_intermediate_references, img4)

      expect(img1).to eq("This is an image ![https://google/image/1](https://google/image/1)")
      expect(img2).to eq("![ticket:1:picture.png](#{attach_url}/1/picture.png)")
      expect(img3).to eq("![picture.png](#{wiki_attachments_url}/WikiFormatting/picture.png)")
      expect(img4).to eq("![trac_logo_mini.png](#{base_url}/trunk/trac/htdocs/trac_logo_mini.png)")
    end
  end

  describe "#convert" do
    it "should convert from trak wiki format to github markdown format" do
      str = <<~WIKI_FORMAT_TEXT
        Some ticket references:
        - Fixed in [1234]
        - Fixed in [1234/mailarch]

        Ticket references:
        - https://foo.bar/trac/foobar/ticket/123
        - ticket:123

        Headings:
        = h1 =
        == h2 ==
        === h3 ===
        ==== h4 ====
        ===== h5 =====
        ====== h6 ======

        New lines formatters:
        foo[[br]]bar\r\nbaz[[BR]]

        Comments:
        - {{{#!comment This is a single line comment}}}
        {{{#!comment
          This is a multiline comment
        }}}

        Html Snippet:
        {{{#!html
        <h1 style="text-align: right; color: blue">
          HTML Test
        </h1>
        }}}

        Code Snippets:
        {{{single line code}}}
        {{{
          multiline
          code
        }}}

        {{{#!ruby
        def foo
          puts "ruby world"
        end
        }}}

        {{{#!python
        def foo:
          print("python world")
        }}}

        Font Styles:
        - '''bold'''
        - ''italic''
        - //italic//

        Links:
        - [https://www.google.com google engine]
        - !UrlDesign
        - UrlDesign
        - Multiple links [https://www.google.com one] in one [https://www.facebook.com two] line.
        - Multiple links [[https://www.google.com|one]] in one [[https://www.facebook.com|two]] line.
        - ![https://www.google.com google single]

        Here are some images:
        - [[Image(https://google/image/1)]]
        - [[Image(ticket:1:picture.png)]]
        - [[Image(wiki:WikiFormatting:picture.png)]]
        - [[Image(source:/trunk/trac/htdocs/trac_logo_mini.png)]]

        Tables:
        || Column 1 || Column 2 || Column 3 ||
        ||  hello   ||  world   ||  hello   ||
        ||  hello   ||  good    ||  world   ||
        ||  hello   ||  bad     ||  world   ||

        || Col 1 || Col 2 || Col 3 ||
        ||  hello   ||  world   ||  hello   ||
        ||  hello   ||  good    ||  world   ||
      WIKI_FORMAT_TEXT

      base_url = options_for_markdown_converter[:base_url]
      attach_url = options_for_markdown_converter[:attachment_options][:url]
      wiki_attachments_url = options_for_markdown_converter[:wiki_attachments_url]

      expected_str = <<~MARKDOWN_FORMAT_TEXT
        Some ticket references:
        - Fixed in https://github.com/repo/commits/abcd123
        - Fixed in https://github.com/repo/commits/abcd123

        Ticket references:
        - #123
        - #123

        Headings:
        # h1
        ## h2
        ### h3
        #### h4
        ##### h5
        ###### h6

        New lines formatters:
        foo
        bar
        baz


        Comments:
        - <!-- This is a single line comment -->
        <!--
          This is a multiline comment

        -->

        Html Snippet:

        <h1 style="text-align: right; color: blue">
          HTML Test
        </h1>


        Code Snippets:
        `single line code`
        ```
          multiline
          code
        ```

        ```ruby
        def foo
          puts "ruby world"
        end

        ```

        ```python
        def foo:
          print("python world")

        ```

        Font Styles:
        - **bold**
        - *italic*
        - _italic_

        Links:
        - [google engine](https://www.google.com)
        - UrlDesign
        - [UrlDesign](https://github.com/#{options_for_markdown_converter[:git_repo]}/wiki/UrlDesign)
        - Multiple links [one](https://www.google.com) in one [two](https://www.facebook.com) line.
        - Multiple links [one](https://www.google.com) in one [two](https://www.facebook.com) line.
        - [https://www.google.com google single]

        Here are some images:
        - ![https://google/image/1](https://google/image/1)
        - ![ticket:1:picture.png](#{attach_url}/1/picture.png)
        - ![picture.png](#{wiki_attachments_url}/WikiFormatting/picture.png)
        - ![trac_logo_mini.png](#{base_url}/trunk/trac/htdocs/trac_logo_mini.png)

        Tables:
        | Column 1 | Column 2 | Column 3 |
        | --- | --- | --- |
        |  hello   |  world   |  hello   |
        |  hello   |  good    |  world   |
        |  hello   |  bad     |  world   |

        | Col 1 | Col 2 | Col 3 |
        | --- | --- | --- |
        |  hello   |  world   |  hello   |
        |  hello   |  good    |  world   |
      MARKDOWN_FORMAT_TEXT

      twf_to_markdown.convert(str)

      expect(str).to eq(expected_str)
    end
  end
end
