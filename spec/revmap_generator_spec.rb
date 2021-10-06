# frozen_string_literal: true

RSpec.describe Tractive::RevmapGenerator do
  let(:revmap_generator) { Tractive::RevmapGenerator.new("abc.fo", "svn://dummy-url/myrepo", "/Users/someuser/somepath", "revmap.txt") }

  context "#extract_info_from_line" do
    it "should extract info from line without revision_count" do
      line = "SVN:123 2021-12-21T21:21:21Z!foo@bar.com"
      expected_hash = info_hash(
        revision: "r123",
        timestamp: "2021-12-21T21:21:21Z",
        author: "foo@bar.com"
      )
      expect(revmap_generator.send(:extract_info_from_line, line)).to eq(expected_hash)
    end
  end

  context "#git_commits" do
    it "should return single commit" do
      info = info_hash(
        revision: "r123",
        timestamp: "2021-12-21T21:21:21Z",
        author: "foo@bar.com"
      )

      commits = [{ sha: "thisisalonglongsha", short_sha: "shortsha1", message: "demo message 1" }]
      allow(revmap_generator).to receive(:commits_from_git_repo).with(info).and_return(commits)

      expect(revmap_generator.send(:git_commits, info)).to eq({ "demo message 1" => ["thisisalonglongsha"] })
    end

    it "should populate @duplicate_commits" do
      info = info_hash(
        revision: "r123",
        timestamp: "2021-12-21T21:21:21Z",
        author: "foo@bar.com"
      )

      commits = [{ sha: "thisisalonglongsha1", short_sha: "shortsha1", message: "demo message 1" }, { sha: "thisisalonglongsha2", short_sha: "shortsha2", message: "demo message 2" }]
      allow(revmap_generator).to receive(:commits_from_git_repo).with(info).and_return(commits)

      expect(revmap_generator.send(:git_commits, info)).to eq({ "demo message 1" => ["thisisalonglongsha1"], "demo message 2" => ["thisisalonglongsha2"] })

      expected_duplicate_commits = {
        "2021-12-21T21:21:21Z" => {
          "demo message 1" => ["thisisalonglongsha1"],
          "demo message 2" => ["thisisalonglongsha2"]
        }
      }
      expect(revmap_generator.instance_variable_get(:@duplicate_commits)).to eq(expected_duplicate_commits)
    end

    it "should use @duplicate_commits when present" do
      info = info_hash(
        revision: "r123",
        timestamp: "2021-12-21T21:21:21Z",
        author: "foo@bar.com"
      )
      duplicate_commits = {
        "2021-12-21T21:21:21Z" => {
          "demo message 1" => ["thisisalonglongsha1"],
          "demo message 2" => ["thisisalonglongsha2"]
        }
      }
      revmap_generator.instance_variable_set(:@duplicate_commits, duplicate_commits)
      expect(revmap_generator.send(:git_commits, info)).to eq({ "demo message 1" => ["thisisalonglongsha1"], "demo message 2" => ["thisisalonglongsha2"] })
    end
  end

  it "should generate correct revmap output for unique timestamps" do
    buffer = StringIO.new
    info = info_hash(revision: "r123", timestamp: "2021-12-21T21:21:21Z", author: "foo@bar.com")

    allow(revmap_generator).to receive(:commits_from_git_repo).with(info).and_return([{ sha: "thisisalonglongsha", short_sha: "shortsha", message: "demo message 1" }])

    revmap_generator.send(:print_revmap_info, info, buffer)

    actual_string = buffer.string
    expected_string = "r123 | thisisalonglongsha\n"
    expect(actual_string).to eq(expected_string)
  end

  it "should generate correct revmap output for multiple revisions with same timestamp" do
    buffer = StringIO.new
    info1 = info_hash(revision: "r123", timestamp: "2021-12-21T21:21:21Z", author: "foo@bar.com")
    info2 = info_hash(revision: "r124", timestamp: "2021-12-21T21:21:21Z", author: "foo@bar.com")

    allow(revmap_generator).to receive(:commits_from_git_repo).with(info1).and_return([{ sha: "thisisalonglongsha1", short_sha: "shortsha1", message: "demo message 1" }, { sha: "thisisalonglongsha2", short_sha: "shortsha2", message: "demo message 2" }])

    allow(revmap_generator).to receive(:commit_message_from_svn).with("r123").and_return("demo message 1")
    allow(revmap_generator).to receive(:commit_message_from_svn).with("r124").and_return("demo message 2")

    revmap_generator.send(:print_revmap_info, info1, buffer)
    revmap_generator.send(:print_revmap_info, info2, buffer)

    actual_string = buffer.string
    expected_string = "r123 | thisisalonglongsha1\nr124 | thisisalonglongsha2\n"
    expect(actual_string).to eq(expected_string)
  end

  it "should generate correct file for unique revisions" do
    buffer = StringIO.new
    info1 = info_hash(revision: "r123", timestamp: "2021-12-21T21:21:21Z", author: "foo@bar.com")
    info2 = info_hash(revision: "r124", timestamp: "2021-12-21T22:22:22Z", author: "bar@baz.com")

    allow(File).to receive(:open).with("revmap.txt", "w+").and_yield(buffer)
    allow(File).to receive(:read).with("abc.fo").and_return("SVN:123 2021-12-21T21:21:21Z!foo@bar.com\nSVN:124 2021-12-21T22:22:22Z!bar@baz.com")
    allow(File).to receive(:foreach).with("abc.fo").and_yield("SVN:123 2021-12-21T21:21:21Z!foo@bar.com").and_yield("SVN:124 2021-12-21T22:22:22Z!bar@baz.com")

    allow(revmap_generator).to receive(:commits_from_git_repo).with(info1).and_return([{ sha: "thisisalonglongsha1", short_sha: "shortsha1", message: "demo message 1" }])
    allow(revmap_generator).to receive(:commits_from_git_repo).with(info2).and_return([{ sha: "thisisalonglongsha2", short_sha: "shortsha2", message: "demo message 2" }])

    revmap_generator.send(:generate)

    actual_string = buffer.string
    expected_string = "r123 | thisisalonglongsha1\nr124 | thisisalonglongsha2\n"
    expect(actual_string).to eq(expected_string)
  end

  it "should generate correct file for multiple revisions with same timestamp" do
    buffer = StringIO.new
    info = info_hash(revision: "r123", timestamp: "2021-12-21T21:21:21Z", author: "foo@bar.com")

    allow(File).to receive(:open).with("revmap.txt", "w+").and_yield(buffer)
    allow(File).to receive(:read).with("abc.fo").and_return("SVN:123 2021-12-21T21:21:21Z!foo@bar.com\nSVN:124 2021-12-21T21:21:21Z!bar@baz.com")
    allow(File).to receive(:foreach).with("abc.fo").and_yield("SVN:123 2021-12-21T21:21:21Z!foo@bar.com").and_yield("SVN:124 2021-12-21T21:21:21Z!bar@baz.com")

    allow(revmap_generator).to receive(:commits_from_git_repo).with(info).and_return([{ sha: "thisisalonglongsha1", short_sha: "shortsha1", message: "demo message 1" }, { sha: "thisisalonglongsha2", short_sha: "shortsha2", message: "demo message 2" }])

    allow(revmap_generator).to receive(:commit_message_from_svn).with("r123").and_return("demo message 1")
    allow(revmap_generator).to receive(:commit_message_from_svn).with("r124").and_return("demo message 2")

    revmap_generator.send(:generate)

    actual_string = buffer.string
    expected_string = "r123 | thisisalonglongsha1\nr124 | thisisalonglongsha2\n"
    expect(actual_string).to eq(expected_string)
  end

  def info_hash(options = {})
    {
      revision: options[:revision],
      revision_count: options[:revision_count],
      timestamp: options[:timestamp],
      count: options[:count],
      author: options[:author]
    }
  end
end
