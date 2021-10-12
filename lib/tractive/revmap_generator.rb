# frozen_string_literal: true

module Tractive
  class RevmapGenerator
    def initialize(input_file, svn_url, svn_local_path, git_local_repo_path, output_file = "revmap.txt")
      @input_file = input_file
      @git_local_repo_path = git_local_repo_path
      @svn_url = svn_url
      @svn_local_path = svn_local_path
      @duplicate_commits = {}
      @duplicate_message_commits = {}
      @last_revision = nil
      @pinwheel = %w[| / - \\]
      @skipped = []
      @output_file = output_file
    end

    def generate
      line_count = File.read(@input_file).scan(/\n/).count
      i = 0

      File.open(@output_file, "w+") do |file|
        File.foreach(@input_file) do |line|
          i += 1
          info = extract_info_from_line(line)
          next if @last_revision == info[:revision]

          @last_revision = info[:revision]
          print_revmap_info(info, file)

          percent = ((i.to_f / line_count) * 100).round(2)
          progress = "=" * (percent.to_i / 2) unless i < 2
          printf("\rProgress: [%<progress>-50s] %<percent>.2f%% %<spinner>s", progress: progress, percent: percent, spinner: @pinwheel.rotate!.first)
        end
      end

      $logger.info "\n\nFollowing revisions are skipped because they don't have a corresponding git commit. #{@skipped}"
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

      if commits.empty?
        @skipped << info[:revision]
      elsif commits.count == 1
        file.puts "#{info[:revision]} | #{commits.values[0]&.join(",")}"
      else
        message = commit_message_from_svn(info[:revision])
        file.puts "#{info[:revision]} | #{@duplicate_commits[info[:timestamp]][message]&.join(",")}"
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
          $logger.warn("'#{sha}' has same timestamp, commiter and commit messgae as '#{commits_hash[message]}'") unless commits_hash[message].nil?
          commits_hash[message] = [sha]
        end
      end

      @duplicate_commits[info[:timestamp]] = commits_hash if commits.count > 1

      commits_hash
    end

    def commit_message_from_svn(revision)
      svn_logs = Tractive::Utilities.svn_log(@svn_url, @svn_local_path, "-r": revision, "--xml": "")
      h = Ox.load(svn_logs, mode: :hash)
      h[:log][:logentry][3][:msg]
    end

    def commits_from_git_repo(info)
      shas_command = "git rev-list --after=#{info[:timestamp]} --until=#{info[:timestamp]} --committer=#{info[:author]} --all"
      shas = Dir.chdir(@git_local_repo_path) do
        `#{shas_command}`
      end

      commits_command = "git rev-list --after=#{info[:timestamp]} --until=#{info[:timestamp]} --committer=#{info[:author]} --all --format='medium'"
      commits = Dir.chdir(@git_local_repo_path) do
        `#{commits_command}`
      end

      regex = /#{shas.split("\n").map { |sha| "(?=commit #{sha})" }.join "|"}/

      commits_arr = []
      commits.split(regex).each do |commit_info|
        commit_hash = {}
        info = commit_info.split("\n", 4)
        commit_hash[:sha] = info[0].split.last
        commit_hash[:message] = info.last.strip.gsub("\n", "").gsub(/\s+/, " ")

        commits_arr << commit_hash
      end

      commits_arr
    end
  end
end
