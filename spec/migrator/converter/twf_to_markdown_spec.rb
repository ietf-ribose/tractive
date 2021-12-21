# frozen_string_literal: false

RSpec.describe Migrator::Converter::TwfToMarkdown do
  let(:twf_to_markdown) { Migrator::Converter::TwfToMarkdown.new(*options_for_markdown_converter.values) }

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

  it "should convert line endings" do
    str = "foo [[br]] bar \r\n baz [[BR]]"

    twf_to_markdown.send(:convert_newlines, str)

    expect(str).to eq("foo \n bar \n baz \n")
  end

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

  it "should convert code snippets" do
    str = "{{{single line code}}} \n {{{ multiline \n code }}}"

    twf_to_markdown.send(:convert_code_snippets, str)

    expect(str).to eq("`single line code` \n ``` multiline \n code ```")
  end

  it "should convert font styles" do
    bold = "'''bold'''"
    italic = "''italic'' //italic//"

    twf_to_markdown.send(:convert_font_styles, bold)
    twf_to_markdown.send(:convert_font_styles, italic)

    expect(bold).to eq("**bold**")
    expect(italic).to eq("*italic* _italic_")
  end

  it "should convert links" do
    str = "[https://www.google.com google engine]"

    twf_to_markdown.send(:convert_links, str)

    expect(str).to eq("[google engine](https://www.google.com)")
  end

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

    twf_to_markdown.send(:revert_image_references, img1)
    twf_to_markdown.send(:revert_image_references, img2)
    twf_to_markdown.send(:revert_image_references, img3)
    twf_to_markdown.send(:revert_image_references, img4)

    expect(img1).to eq("This is an image ![https://google/image/1](https://google/image/1)")
    expect(img2).to eq("![ticket:1:picture.png](#{attach_url}/1/picture.png)")
    expect(img3).to eq("![picture.png](#{wiki_attachments_url}/WikiFormatting/picture.png)")
    expect(img4).to eq("![trac_logo_mini.png](#{base_url}/trunk/trac/htdocs/trac_logo_mini.png)")
  end

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
      foo [[br]] bar \r\n baz [[BR]]

      Comments:
      - {{{#!comment This is a single line comment}}}
      - {{{#!comment
          This is a multiline comment
        }}}

      Html Snippet:
      {{{#!html
      <h1 style="text-align: right; color: blue">
        HTML Test
      </h1>
      }}}

      Code Snippets:
      - {{{single line code}}}
      - {{{
          multiline
          code
        }}}

      Font Styles:
      - '''bold'''
      - ''italic''
      - //italic//

      External Links:
      - [https://www.google.com google engine]

      Here are some images:
      - [[Image(https://google/image/1)]]
      - [[Image(ticket:1:picture.png)]]
      - [[Image(wiki:WikiFormatting:picture.png)]]
      - [[Image(source:/trunk/trac/htdocs/trac_logo_mini.png)]]
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
      foo\s
       bar\s
       baz\s


      Comments:
      - <!-- This is a single line comment -->
      - <!--
          This is a multiline comment
      \s\s
      -->

      Html Snippet:

      <h1 style="text-align: right; color: blue">
        HTML Test
      </h1>


      Code Snippets:
      - `single line code`
      - ```
          multiline
          code
        ```

      Font Styles:
      - **bold**
      - *italic*
      - _italic_

      External Links:
      - [google engine](https://www.google.com)

      Here are some images:
      - ![https://google/image/1](https://google/image/1)
      - ![ticket:1:picture.png](#{attach_url}/1/picture.png)
      - ![picture.png](#{wiki_attachments_url}/WikiFormatting/picture.png)
      - ![trac_logo_mini.png](#{base_url}/trunk/trac/htdocs/trac_logo_mini.png)
    MARKDOWN_FORMAT_TEXT

    twf_to_markdown.convert(str)

    expect(str).to eq(expected_str)
  end
end
