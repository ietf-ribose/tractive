# frozen_string_literal: true

RSpec.describe Migrator::Wikis::MigrateFromDb do
  context "#verify_options" do
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

  context "#verify_locations" do
    it "should `exit` if repo-path directory is missing" do
      expect { Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki("repo-path" => "invalid-location"), cfg: CONFIG).send(:verify_locations) }.to raise_error(SystemExit)
    end

    it "should `not exit` and return `nil` if repo-path directory is present" do
      expect(Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG).send(:verify_locations)).to be_nil
    end
  end

  context "#cleanse_filename" do
    it "should cleanse filename" do
      filename = "Hello-World<hello>/"
      wiki_migrator = Migrator::Wikis::MigrateFromDb.new(opts: options_for_wiki, cfg: CONFIG)
      expect(wiki_migrator.send(:cleanse_filename, filename)).to eq("Hello_World_hello__")
    end
  end

  context "#skip_file" do
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

  context "#generate_author" do
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

  def options_for_wiki(options = {})
    {
      "repo-path" => "spec/files/trac_test.wiki",
      "attachment-base-url" => "http://base-url/for/wiki"
    }.merge(options)
  end
end
