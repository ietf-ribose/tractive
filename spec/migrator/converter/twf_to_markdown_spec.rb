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
      str = <<~WIKI_COMMENT_TEXT
        single line comment: {{{#!comment this is a comment}}}

        multiline comment:
        {{{#!comment
        this is a comment with a codeblock
        {{{#!ruby
          def foo
            puts "bar"
          end
        }}}
        }}}
      WIKI_COMMENT_TEXT

      expected_str = <<~CONVERTED_STR
        single line comment: <!-- this is a comment -->

        multiline comment:
        <!--
        this is a comment with a codeblock
        {{{#!ruby
          def foo
            puts "bar"
          end
        }}}

        -->
      CONVERTED_STR

      twf_to_markdown.send(:convert_comments, str)

      expect(str).to eq(expected_str)
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
        WikiStart
        UrlDesign
        badUrlDesign
        good ProjectSetup
      LINKS

      expected_str = <<~CONVERTED_LINKS
        HelloWorld
        [Home](https://github.com/foo/bar/wiki/Home)
        [UrlDesign](https://github.com/#{options_for_markdown_converter[:options][:git_repo]}/wiki/UrlDesign)
        badUrlDesign
        good [ProjectSetup](https://github.com/#{options_for_markdown_converter[:options][:git_repo]}/wiki/ProjectSetup)
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end

    it "should convert external links in single square bracket" do
      str = <<~LINKS
        [https://www.google.com google single]
        [https://www.google.com]
        [comment:3 fenner@research.att.com]
        Link in the middle [https://www.google.com Google] of line
        Link without name in [https://www.google.com] middle of line.
        Multiple links [https://www.google.com one] in one [https://www.facebook.com facebook two] line.
      LINKS

      expected_str = <<~CONVERTED_LINKS
        [google single](https://www.google.com)
        [https://www.google.com](https://www.google.com)
        [comment:3 fenner@research.att.com]
        Link in the middle [Google](https://www.google.com) of line
        Link without name in [https://www.google.com](https://www.google.com) middle of line.
        Multiple links [one](https://www.google.com) in one [facebook two](https://www.facebook.com) line.
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
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

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end

    it "should convert `wiki` links" do
      str = <<~LINKS
        [wiki:WikiStart#CodeSprints Code Sprints]
        [wiki:WikiStart]
      LINKS

      expected_str = <<~CONVERTED_LINKS
        [Code Sprints](https://github.com/foo/bar/wiki/Home#code-sprints)
        [Home](https://github.com/foo/bar/wiki/Home#)
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end

    context "source links" do
      it "convert for files" do
        str = "[source:trunk/ietf/bin/expire-ids expire_ids]"

        expected_str = "[expire_ids](https://github.com/foo/bar/blob/main/ietf/bin/expire-ids)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert SHA references for file" do
        str = "[source:trunk/ietf/ipr/models.py@107#L78 IprDetail]"
        expected_str = "[IprDetail](https://github.com/foo/bar/blob/a1b2c3/ietf/ipr/models.py#L78)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert SHA references for file with line numbers" do
        str = <<~LINKS
          [source:trunk/ietf/doc/expire.py?rev=7921#L145 doc.expire.clean_up_draft_files()]
          [source:trunk/ietf/doc/views_draft.py?rev=7921#L341 doc.views_draft.replaces()]
        LINKS

        expected_str = <<~CONVERTED_LINKS
          [doc.expire.clean_up_draft_files()](https://github.com/foo/bar/blob/ababab/ietf/doc/expire.py#L145)
          [doc.views_draft.replaces()](https://github.com/foo/bar/blob/ababab/ietf/doc/views_draft.py#L341)
        CONVERTED_LINKS

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert SHA references for branch" do
        str = "[source:sprint/77/henrik@2118]"
        expected_str = "[sprint/77/henrik@2118](https://github.com/foo/bar/tree/ab1234)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert for tags" do
        str = <<~LINKS
          [source:tags/]
          [source:tags/2.46]
          [source:tags/2.46/changelog v2.46]
          [source:tags/?order=date&desc=1 tags/]
        LINKS

        expected_str = <<~CONVERTED_LINKS
          [tags/](https://github.com/foo/bar/tags)
          [tags/2.46](https://github.com/foo/bar/tree/2.46)
          [v2.46](https://github.com/foo/bar/blob/2.46/changelog)
          [tags/](https://github.com/foo/bar/tags)
        CONVERTED_LINKS

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert for all branches" do
        str = "[source:branch/]"
        expected_str = "[branch/](https://github.com/foo/bar/branches/all?query=branch)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert to main branch if link missing" do
        str = "[source: source code repository]"
        expected_str = "[source code repository](https://github.com/foo/bar/)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert for main branch" do
        str = "[source:trunk/]"
        expected_str = "[trunk/](https://github.com/foo/bar/tree/main)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert for branch names" do
        str = <<~LINKS
          [source:branch/yaco/idsubmit ID Submission Tool Repository]
          [source:/branch/yaco/liaison/ liaison]
        LINKS

        expected_str = <<~CONVERTED_LINKS
          [ID Submission Tool Repository](https://github.com/foo/bar/tree/branch/yaco/idsubmit)
          [liaison](https://github.com/foo/bar/tree/branch/yaco/liaison)
        CONVERTED_LINKS

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert partial branches to filters" do
        str = <<~LINKS
          [source:personal/]
          [source:branch/hawk hawk]
        LINKS

        expected_str = <<~CONVERTED_LINKS
          [personal/](https://github.com/foo/bar/branches/all?query=personal)
          [hawk](https://github.com/foo/bar/branches/all?query=branch/hawk)
        CONVERTED_LINKS

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end

      it "convert without links" do
        str = "[source: source code repository]"
        expected_str = "[source code repository](https://github.com/foo/bar/)"

        twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
        twf_to_markdown.send(:revert_intermediate_references, str)

        expect(str).to eq(expected_str)
      end
    end

    it "should not convert links starting with `!`" do
      str = <<~LINKS
        !UrlDesign !ProjectSetup
        ![[https://www.google.com]]
        Don't make link in middle ![https://www.google.com google single] of the line.
      LINKS

      expected_str = <<~CONVERTED_LINKS
        UrlDesign ProjectSetup
        [[https://www.google.com]]
        Don't make link in middle [https://www.google.com google single] of the line.
      CONVERTED_LINKS

      twf_to_markdown.send(:convert_links, str, options_for_markdown_converter[:options][:git_repo])
      twf_to_markdown.send(:revert_intermediate_references, str)

      expect(str).to eq(expected_str)
    end
  end

  describe "#source_git_path" do
    context "input empty string" do
      it "returns empty string" do
        return_value = twf_to_markdown.send(:source_git_path, "")
        expect(return_value).to be_empty
      end
    end

    context "when input start with `trunk/`" do
      it "returns main branch path" do
        return_value1 = twf_to_markdown.send(:source_git_path, "trunk/")
        return_value2 = twf_to_markdown.send(:source_git_path, "/trunk/")

        expect(return_value1).to eq("tree/main")
        expect(return_value2).to eq("tree/main")
      end

      it "returns main branch file path with line number" do
        return_value = twf_to_markdown.send(:source_git_path, "trunk/ietf/ipr/models.py@107#L78")
        expect(return_value).to eq("blob/a1b2c3/ietf/ipr/models.py#L78")
      end
    end

    context "when input is in source folder list" do
      it "returns filter branches path with filter `query=branch`" do
        return_value1 = twf_to_markdown.send(:source_git_path, "branch/")
        return_value2 = twf_to_markdown.send(:source_git_path, "/branch/")

        expect(return_value1).to eq("branches/all?query=branch")
        expect(return_value2).to eq("branches/all?query=branch")
      end

      it "returns filter branches path with filter `query=branch/hawk`" do
        return_value = twf_to_markdown.send(:source_git_path, "/branch/hawk")
        expect(return_value).to eq("branches/all?query=branch/hawk")
      end

      it "returns filter branches path with filter `query=personal`" do
        return_value = twf_to_markdown.send(:source_git_path, "personal/")
        expect(return_value).to eq("branches/all?query=personal")
      end
    end

    context "when input is branch path" do
      context "with complete path" do
        it "returns branch path" do
          return_value = twf_to_markdown.send(:source_git_path, "/branch/ssw/agenda/")
          expect(return_value).to eq("tree/branch/ssw/agenda")
        end
      end
    end

    context "when input is tag path" do
      it "returns all tags path" do
        return_value1 = twf_to_markdown.send(:source_git_path, "tags/")
        return_value2 = twf_to_markdown.send(:source_git_path, "/tags/")

        expect(return_value1).to eq("tags")
        expect(return_value2).to eq("tags")
      end

      it "returns tag path" do
        return_value = twf_to_markdown.send(:source_git_path, "/tags/4.6/")
        expect(return_value).to eq("tree/4.6")
      end
    end
  end

  describe "#file?" do
    context "when nil input" do
      it "return false" do
        return_value = twf_to_markdown.send(:file?, nil)
        expect(return_value).to be false
      end
    end

    context "when path ends with a value in wiki_extensions" do
      it "returns true" do
        return_value = twf_to_markdown.send(:file?, "path/abc.py")
        expect(return_value).to be true
      end
    end

    context "when path does not ends with a value in wiki_extensions" do
      it "returns false" do
        return_value = twf_to_markdown.send(:file?, "path/abc")
        expect(return_value).to be false
      end
    end
  end

  describe "#wiki_path" do
    context "when path in source_folders" do
      it "returns all branches with filter" do
        return_value = twf_to_markdown.send(:wiki_path, "branch/hawk")
        expect(return_value).to eq("branches/all?query=branch/hawk")
      end
    end

    context "when tags path" do
      it "returns tags index page path" do
        return_value = twf_to_markdown.send(:wiki_path, "tags")
        expect(return_value).to eq("tags")
      end
    end

    context "when file path" do
      it "returns file path" do
        return_value = twf_to_markdown.send(:wiki_path, "main/changelog")
        expect(return_value).to eq("blob/main/changelog")
      end

      it "returns file path with line number" do
        return_value = twf_to_markdown.send(:wiki_path, "main/ietf/doc/views_draft.py", "L341")
        expect(return_value).to eq("blob/main/ietf/doc/views_draft.py#L341")
      end
    end

    context "when branch path" do
      it "returns file path" do
        return_value = twf_to_markdown.send(:wiki_path, "main")
        expect(return_value).to eq("tree/main")
      end
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
        - Multiple source links [source:branch/] in one [source:personal/] line.
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

        || Column 1 || Column 2 || Column 3
        ||  hello   ||  world   ||  hello
        ||  hello   ||  good    ||  world how are you?
        ||  hello   ||  bad     ||  world

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
        - [UrlDesign](https://github.com/#{options_for_markdown_converter[:options][:git_repo]}/wiki/UrlDesign)
        - Multiple links [one](https://www.google.com) in one [two](https://www.facebook.com) line.
        - Multiple links [one](https://www.google.com) in one [two](https://www.facebook.com) line.
        - Multiple source links [branch/](https://github.com/foo/bar/branches/all?query=branch) in one [personal/](https://github.com/foo/bar/branches/all?query=personal) line.
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

        | Column 1 | Column 2 | Column 3 |
        | --- | --- | --- |
        |  hello   |  world   |  hello |
        |  hello   |  good    |  world how are you? |
        |  hello   |  bad     |  world |

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
