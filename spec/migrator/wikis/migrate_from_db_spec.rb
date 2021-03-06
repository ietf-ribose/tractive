# frozen_string_literal: true

RSpec.describe Migrator::Wikis::MigrateFromDb do
  describe "#verify_options" do
    it "should `exit` if attachment-base-url is missing" do
      expect { Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki("attachment-base-url" => ""), cfg: CONFIG).send(:verify_options) }.to raise_error(SystemExit)
    end

    it "should `exit` if repo-path is missing" do
      expect { Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki("repo-path" => ""), cfg: CONFIG).send(:verify_options) }.to raise_error(SystemExit)
    end

    it "should `exit` if both repo-path and attachment-base-url are missing" do
      expect { Migrator::Wikis::MigrateFromDb.new(opts: { "repo-path" => "", "attachment-base-url" => "" }, cfg: CONFIG).send(:verify_options) }.to raise_error(SystemExit)
    end

    it "should `not exit` and return `nil` if both options are present" do
      expect(Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG).send(:verify_options)).to be_nil
    end
  end

  describe "#verify_locations" do
    it "should `exit` if repo-path directory is missing" do
      expect { Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki("repo-path" => "invalid-location"), cfg: CONFIG).send(:verify_locations) }.to raise_error(SystemExit)
    end

    it "should `not exit` and return `nil` if repo-path directory is present" do
      expect(Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG).send(:verify_locations)).to be_nil
    end
  end

  describe "#filename_for_wiki" do
    it "should return `Home.md` for default home-page-name" do
      wiki = Tractive::Wiki.first(name: "WikiStart")

      expect(
        Migrator::Wikis::MigrateFromDb.new(
          opts: options_for_wiki, cfg: CONFIG
        ).send(:filename_for_wiki, wiki)
      ).to eq("Home.md")
    end

    it "should return `Home.md` when home-page-name is passed in options" do
      wiki = Tractive::Wiki.first(name: "ProjectSetup")

      expect(
        Migrator::Wikis::MigrateFromDb.new(
          opts: options_for_wiki("home-page-name" => "ProjectSetup"), cfg: CONFIG
        ).send(:filename_for_wiki, wiki)
      ).to eq("Home.md")
    end

    it "should return `Model.md`" do
      wiki = Tractive::Wiki.first(name: "Model")

      expect(
        Migrator::Wikis::MigrateFromDb.new(
          opts: options_for_wiki, cfg: CONFIG
        ).send(:filename_for_wiki, wiki)
      ).to eq("Model.md")
    end
  end

  describe "#cleanse_filename" do
    it "should cleanse filename" do
      filename = "Hello-World<hello>/"
      wiki_migrator = Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG)
      expect(wiki_migrator.send(:cleanse_filename, filename)).to eq("Hello_World_hello__")
    end
  end

  describe "#skip_file" do
    let(:wiki_migrator) { Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG) }

    it "should return `true` if filename start with `Trac`" do
      expect(wiki_migrator.send(:skip_file, "TracReports")).to be true
      expect(wiki_migrator.send(:skip_file, "TracPlugins")).to be true
    end

    it "should return `true` if filename start with `Wiki` and does not start with `WikiStart`" do
      expect(wiki_migrator.send(:skip_file, "WikiRestructuredTextLinks")).to be true
      expect(wiki_migrator.send(:skip_file, "WikiProcessors")).to be true
    end

    it "should return `false` if filename does not start with `Trac` or start with `WikiStart`" do
      expect(wiki_migrator.send(:skip_file, "WikiStart")).to be false
      expect(wiki_migrator.send(:skip_file, "UrlDesign")).to be false
      expect(wiki_migrator.send(:skip_file, "UrlTest")).to be false
    end
  end

  describe "#generate_author" do
    let(:wiki_migrator) { Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG) }

    it "should return `empty` if author is empty" do
      expect(wiki_migrator.send(:generate_author, "")).to be_empty
    end

    it "should return `henrik <henrik@levkowetz.com>` when author is `henrik@levkowetz.com`" do
      expect(wiki_migrator.send(:generate_author, "henrik@levkowetz.com")).to eq("henrik <henrik@levkowetz.com>")
    end

    it "should return `Fenner <fenner@research.att.com>` when author is `fenner@research.att.com`" do
      expect(wiki_migrator.send(:generate_author, "fenner@research.att.com")).to eq("fenner <fenner@research.att.com>")
    end
  end

  describe "#wiki_attachments" do
    let(:wiki_migrator) { described_class.new(opts: options_for_wiki, cfg: CONFIG) }

    it "should append attachments to wikis if present" do
      wiki = Tractive::Wiki.latest_versions.first(name: "Model")

      wiki_text = wiki_migrator.send(:wiki_attachments, wiki)
      expect(wiki_text).to include("# Attachments\n\n- [models.pdf](http://base-url/for/wiki/68c/68c2cc7f0ceaa3e499ecb4db331feb4debbbcc23/96272cf52834b1fb60bdb3c268a96e7135fd87ff.pdf)")
    end

    it "should not append attachments to wikis if not present" do
      wiki = Tractive::Wiki.latest_versions.first(name: "CodeRepository")

      wiki_text = wiki_migrator.send(:wiki_attachments, wiki)
      expect(wiki_text).not_to include("# Attachments\n\n")
    end
  end

  def options_for_wiki(options = {})
    {
      "repo-path" => "spec/files/trac_test.wiki",
      "attachment-base-url" => "http://base-url/for/wiki",
      "home-page-name" => "WikiStart"
    }.merge(options)
  end
end
