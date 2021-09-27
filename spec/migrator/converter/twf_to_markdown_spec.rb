# frozen_string_literal: false

RSpec.describe Migrator::Converter::TwfToMarkdown do
  let(:twf_to_markdown) { Migrator::Converter::TwfToMarkdown.new(*options_for_markdown_converter.values) }

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

  it "should convert code snippets" do
    str = "{{{single line code}}} \n {{{ multiline \n code }}}"

    twf_to_markdown.send(:convert_code_snippets, str)

    expect(str).to eq("`single line code` \n ``` multiline \n code ```")
  end

  it "should convert font styles" do
    bold = "'''bold'''"
    italic = "''italic''  //italic//"

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
    attach_url = options_for_markdown_converter[:attach_url]
    wiki_attachments_url = options_for_markdown_converter[:wiki_attachments_url]

    twf_to_markdown.send(:convert_image, img1, base_url, attach_url, wiki_attachments_url)
    twf_to_markdown.send(:convert_image, img2, base_url, attach_url, wiki_attachments_url)
    twf_to_markdown.send(:convert_image, img3, base_url, attach_url, wiki_attachments_url)
    twf_to_markdown.send(:convert_image, img4, base_url, attach_url, wiki_attachments_url)

    expect(img1).to eq("This is an image ![https://google/image/1](https://google/image/1)")
    expect(img2).to eq("![ticket:1:picture.png](#{attach_url}/1/picture.png)")
    expect(img3).to eq("![picture.png](#{wiki_attachments_url}/picture.png)")
    expect(img4).to eq("![trac_logo_mini.png](#{base_url}/trunk/trac/htdocs/trac_logo_mini.png)")
  end
end
