# frozen_string_literal: true

module Tractive
  class RevmapGenerator
    def initialize(input_file, svn_url, git_repo_path)
      @input_file = input_file
      @git_repo_path = git_repo_path
      @svn_url = svn_url
      @duplicate_commits = {}
      @duplicate_message_commits = {}
      @last_revision = nil
      @pinwheel = %w[| / - \\]
      @output_file = "revmap.txt"
    end

    def generate
      line_count = File.read("postfind.fo").scan(/\n/).count
      i = 0

      File.open(@output_file, "w+") do |file|
        File.foreach("postfind.fo") do |line|
          info = extract_info_from_line(line)
          next if @last_revision == info[:revision]

          @last_revision = info[:revision]
          print_revmap_info(info, file)

          percent = ((i.to_f / line_count) * 100).round(2)
          progress = "=" * (percent.to_i / 2) unless i < 2
          printf("\rProgress: [%<progress>-50s] %<percent>.2f%% %<spinner>s", progress: progress, percent: percent, spinner: @pinwheel.rotate!.first)
          i += 1
        end
      end
    end

    private

    def extract_info_from_line(line)
      info = {}

      info[:revision], timestamp_author = line.split
      info[:revision], info[:revision_count] = info[:revision].split(".")
      info[:revision].gsub!("SVN:", "r")
      info[:timestamp], author_count = timestamp_author.split("!")
      info[:author], info[:count] = author_count.split(":")

      info
    end

    def print_revmap_info(info, file)
      # get sha from git api
      commits = git_commits(info)

      if commits.count == 1
        file.puts "#{info[:revision]} | #{commits.values[0].join(",")}"
      else
        message = commit_message_from_svn(info[:revision])
        file.puts "#{info[:revision]} | #{@duplicate_commits[info[:timestamp]][message].join(",")}"
      end
    end

    def git_commits(info)
      return @duplicate_commits[info[:timestamp]] if @duplicate_commits[info[:timestamp]]

      # get commits from git dir
      commits = commits_from_git_repo(info)

      commits_hash = {}
      commits.each do |commit|
        message = commit[:message]
        sha = commit[:sha]

        if commits_hash[message]
          commits_hash[message] << sha
        else
          commits_hash[message] = [sha]
        end
      end

      @duplicate_commits[info[:timestamp]] = commits_hash if commits.count > 1

      commits_hash
    end

    def commit_message_from_svn(revision)
      svn_logs = Tractive::Utilities.svn_log(@svn_url, "-r": revision, "--xml": "")
      h = Ox.load(svn_logs, mode: :hash)
      h[:log][:logentry][3][:msg]
    end

    def commits_from_git_repo(info)
      command = "git rev-list --after=#{info[:timestamp]} --until=#{info[:timestamp]} --committer=#{info[:author]} --all --format='%cd|%h~|~%s' --date=format:'%Y-%m-%dT%H:%M:%SZ'"
      commits = Dir.chdir(@git_repo_path) do
        `#{command}`
      end

      commits_arr = []
      commits.split("\n").each_slice(2) do |sha_hash, commit_info|
        commit_hash = {}
        commit_hash[:sha] = sha_hash.split.last
        commit_hash[:short_sha], commit_hash[:message] = commit_info.split("~|~")

        commits_arr << commit_hash
      end

      commits_arr
    end
  end
end
