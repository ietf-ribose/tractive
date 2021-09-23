# frozen_string_literal: true

require_relative "engine/markdown_converter"
require_relative "engine/migrate_from_db"
require_relative "engine/migrate_from_file"
require_relative "engine/migrate_to_file"

# Service to perform migrations
module Migrator
  class Engine
    include Migrator::Engine::MarkdownConverter
    include Migrator::Engine::MigrateFromDb
    include Migrator::Engine::MigrateToFile
    include Migrator::Engine::MigrateFromFile

    def initialize(args)
      # def initialize(trac, github, users, labels, revmap, attachurl, singlepost, safetychecks, mockdeleted = false)
      db                = args[:db]
      github            = args[:cfg]["github"]
      users             = args[:cfg]["users"]
      labels            = args[:cfg]["labels"]
      milestones        = args[:cfg]["milestones"]
      attachurl         = args[:opts][:attachurl] || args[:cfg].dig("attachments", "url")
      singlepost        = args[:opts][:singlepost]
      safetychecks      = !(args[:opts][:fast])
      mockdeleted       = args[:opts][:mockdeleted]
      tracticketbaseurl = args[:cfg]["trac"]["ticketbaseurl"]
      start_ticket      = args[:opts][:start]
      filter_closed     = args[:opts][:openedonly]
      input_file_name   = args[:opts][:importfromfile]

      @filter_applied   = args[:opts][:filter]
      @filter_options   = { column_name: args[:opts][:columnname], operator: args[:opts][:operator], column_value: args[:opts][:columnvalue] }

      @trac  = Tractive::Trac.new(db)
      @repo  = github["repo"]
      @token = github["token"]
      @client = GithubApi::Client.new(access_token: @token)

      if input_file_name
        @from_file = input_file_name
        file = File.open(@from_file, "r")
        @input_file = JSON.parse(file.read)
        file.close
      end

      @milestonesfromtrac = milestones

      @users = users.to_h

      @labels_cfg        = labels.transform_values(&:to_h)
      @ticket_to_issue   = {}
      @trac_mails_cache  = {}
      @mockdeleted       = mockdeleted || @filter_applied
      @tracticketbaseurl = tracticketbaseurl

      $logger.debug("Get highest in #{@repo}")
      issues = @client.issues(@repo, { filter: "all",
                                       state: "all",
                                       sort: "created",
                                       direction: "desc" })

      @last_created_issue = issues.empty? ? 0 : issues[0]["number"].to_i

      $logger.info("created issue on GitHub is '#{@last_created_issue}' #{issues.count}")

      load_milestone_map

      dry_run_output_file = args[:cfg][:dry_run_output_file] || "#{Dir.pwd}/dryrun_out.json"

      @changeset_base_url = args[:cfg]["trac"]["changeset_base_url"]
      @dry_run          = args[:opts][:dryrun]
      @output_file      = File.new(dry_run_output_file, "w+")
      @delimiter        = "{"
      @revmap           = load_revmap_file(args[:opts][:revmapfile] || args[:cfg]["revmapfile"])
      @attachurl        = attachurl
      @singlepost       = singlepost
      @safetychecks     = safetychecks
      @start_ticket     = (start_ticket || (@last_created_issue + 1)).to_i
      @filter_closed    = filter_closed
      @uri_parser = URI::Parser.new
    end

    def map_user(user)
      @users[user] || user
    end

    def map_assignee(user)
      @users[user]
    end

    def migrate
      if @dry_run
        migrate_to_file
      elsif @from_file
        migrate_from_file
      else
        migrate_from_db
      end
    end

    private

    def load_milestone_map
      read_milestones_from_github

      newmilestonekeys = @milestonesfromtrac.keys - @milestonemap.keys

      newmilestonekeys.each do |milestonelabel|
        milestone           = {
          "title" => milestonelabel.to_s,
          "state" => @milestonesfromtrac[milestonelabel][:completed].nil? ? "open" : "closed",
          "description" => @milestonesfromtrac[milestonelabel][:description] || "no description in trac",
          "due_on" => "2012-10-09T23:39:01Z"
        }
        due                 = @milestonesfromtrac[milestonelabel][:due]
        milestone["due_on"] = Time.at(due / 1_000_000).strftime("%Y-%m-%dT%H:%M:%SZ") if due

        $logger.info "creating #{milestone}"

        @client.create_milestone(@repo, milestone)
      end

      read_milestones_from_github

      $logger.info("Last created issue on GitHub is '#{@last_created_issue}'")
      nil
    end

    def read_milestones_from_github
      milestonesongithub = @client.milestones(@repo, { state: "all",
                                                       sort: "due_on",
                                                       direction: "desc" })
      @milestonemap = milestonesongithub.map { |i| [i["title"], i["number"]] }.to_h
      nil
    end

    # returns the author mail if found, otherwise author itself
    def trac_mail(author)
      return @trac_mails_cache[author] if @trac_mails_cache.key?(author)

      # tries to retrieve the email from trac db
      data = @trac.sessions.select(:value).where(Sequel.lit('name = "email" AND sid = ?', author))
      return (@trac_mails_cache[author] = data.first[:value]) if data.count == 1

      (@trac_mails_cache[author] = author) # not found
    end

    # Format time for github API
    def format_time(time)
      time = Time.at(time / 1e6, time % 1e6)
      time.strftime("%FT%TZ")
    end

    def compose_issue(ticket)
      body   = ""
      closed = nil

      # summary line:
      # body += %i[id component priority resolution].map do |cat|
      #   ticket[cat] and !ticket[cat].to_s.lstrip.empty? and
      #     "**#{cat}:** #{ticket[cat]}"
      # end.select { |x| x }.join(" | ")

      # Initial report
      # TODO: respect ticket[:changetime]
      body += "\n\n" unless @singlepost
      body += ticket_change(@singlepost, {
                              ticket: ticket[:id],
                              time: ticket[:time],
                              author: ticket[:reporter],
                              assigne: ticket[:owner],
                              field: :initial,
                              oldvalue: nil,
                              newvalue: ticket[:description]
                            })["body"]

      changes = if ticket.is_a? Hash
                  []
                else
                  ticket.all_changes
                end

      # replay all changes in chronological order:
      comments = changes.map { |x| ticket_change(@singlepost, x) }.select { |x| x }.to_a
      if @singlepost
        body += comments.map { |x| x["body"] }.join("\n")
        comments = []
      end

      labels = Set[]
      changes.each do |x|
        del = @labels_cfg.fetch(x[:field], {})[x[:oldvalue]]
        # add = @labels_cfg.fetch(x[:field], {})[x[:newvalue]]
        @labels_cfg.fetch(x[:field], {})[x[:newvalue]]
        labels.delete(del) if del
        # labels.add(add) if add
        closed = x[:time] if (x[:field] == "status") && (x[:newvalue] == "closed")
      end

      # we separate labels from badges
      # labels: are changed frequently in the lifecycle of a ticket, therefore are transferred to github lables
      # badges: are basically fixed  and are transferred to a metadata table in the ticket

      badges = Set[]

      badges.add(@labels_cfg.fetch("component", {})[ticket[:component]])
      badges.add(@labels_cfg.fetch("type", {})[ticket[:type]])
      badges.add(@labels_cfg.fetch("resolution", {})[ticket[:resolution]])
      badges.add(@labels_cfg.fetch("version", {})[ticket[:version]])

      labels.add(@labels_cfg.fetch("severity", {})[ticket[:severity]])
      labels.add(@labels_cfg.fetch("priority", {})[ticket[:priority]])
      labels.add(@labels_cfg.fetch("tracstate", {})[ticket[:status]])
      labels.delete(nil)

      keywords = ticket[:keywords]
      if keywords
        if ticket[:keywords].downcase == "discuss"
          labels.add(@labels_cfg.fetch("keywords", {})[ticket[:keywords].downcase])
        else
          badges.add(@labels_cfg.fetch("keywords", {})[ticket[:keywords]])
        end
      end
      # If the field is not set, it will be nil and generate an unprocessable json

      milestone = @milestonemap[ticket[:milestone]]

      # compute footer
      footer = "_Issue migrated from trac:#{ticket[:id]} at #{Time.now}_"

      # compute badgetabe
      #

      github_assignee = map_assignee(ticket[:owner])

      badges     = badges.to_a.compact.sort
      badgetable = badges.map { |i| %(`#{i}`) }.join(" ")
      badgetable += begin
        "   |    by #{trac_mail(ticket[:reporter])}"
      rescue StandardError
        "deleted Ticket"
      end
      # badgetable += "   |   **->#{ticket[:owner]}**"  # note that from github to gitlab we loose the assigne

      # compose body
      body = [badgetable, body, footer].join("\n\n___\n")

      labels.add("owner:#{github_assignee}")

      issue = {
        "title" => ticket[:summary],
        "body" => body,
        "labels" => labels.to_a,
        "closed" => ticket[:status] == "closed",
        "created_at" => format_time(ticket[:time]),
        "milestone" => milestone
      }

      if @users.key?(ticket[:owner])
        owner = trac_mail(ticket[:owner])
        github_owner = @users[owner]
        $logger.debug("..owner in trac: #{owner}")
        $logger.debug("..assignee in GitHub: #{github_owner}")
        issue["assignee"] = github_owner
      end

      ### as the assignee stuff is pretty fragile, we do not assign at all
      # issue['assignee'] = github_assignee if github_assignee

      if ticket[:changetime]
        # issue["updated_at"] = format_time(ticket[:changetime])
      end

      if issue["closed"] && closed
        #  issue["closed_at"] = format_time(closed)
      end

      {
        "issue" => issue,
        "comments" => comments
      }
    end

    def ticket_change(append, meta)
      # kind
      kind = if meta[:ticket]
               meta[:field].to_s
             else
               "attachment"
             end
      kind = "title" if kind == "summary"

      # don't care
      return unless interested_in_change?(kind, meta[:newvalue])

      # author
      author = meta[:author]
      author = trac_mail(author)
      author = "@#{map_user(author)}" if @users.key?(author)

      text = ""

      if kind != "initial"
        text += "\n___\n" if append
        text += "_#{author}_ " if author
      end

      case kind
      when "owner", "status", "title", "resolution", "priority", "component", "type", "severity", "platform", "milestone"
        old = meta[:oldvalue]
        new = meta[:newvalue]
        if old && new
          text += "_changed #{kind} from `#{old}` to `#{new}`_"
        elsif old
          text += "_removed #{kind} (was `#{old}`)_"
        elsif new
          text += "_set #{kind} to `#{new}`_"
        end

      when :initial, "initial"
        body = meta[:newvalue]
        # text += "created the issue\n\n"
        if body && !body.lstrip.empty?
          # text += "\n___\n" if not append
          text += rtf_to_markdown(body, @tracticketbaseurl, @attachurl, @changeset_base_url)
        end

      when "comment"
        body      = meta[:newvalue]
        changeset = body.match(/In \[changeset:"(\d+)/).to_a[1]
        text += if changeset
                  # changesethash = @revmap[changeset]
                  "_committed #{Tractive::Utilities.map_changeset(changeset)}_"
                else
                  "_commented_\n\n"
                end

        text += "\n___\n" unless append
        text += rtf_to_markdown(body, @tracticketbaseurl, @attachurl, @changeset_base_url) if body

      when "attachment"
        text += "_uploaded file "
        name = meta[:filename]
        body = meta[:description]
        if @attachurl
          url = @uri_parser.escape("#{@attachurl}/#{meta[:id]}/#{name}")
          text += "[`#{name}`](#{url})"
          body += "\n![#{name}](#{url})" if [".png", ".jpg", ".gif"].include? File.extname(name).downcase
        else
          text += "`#{name}`"
        end
        text += " (#{(meta[:size] / 1024.0).round(1)} KiB)_"
        text += "\n\n#{body}"

      when "description"
        # (ticket[:description] already contains the new value,
        # so there is no need to update)
        text += "_edited the issue description_"

      else
        # this should not happen
        text += "changed #{kind} which not transferred by trac-hub"
      end

      {
        "body" => text,
        "created_at" => format_time(meta[:time])
      }
    end

    def load_revmap_file(revmapfile)
      # load revision mapping file and convert it to a hash.
      # This revmap file allows to map between SVN revisions (rXXXX)
      # and git commit sha1 hashes.
      revmap = nil
      if revmapfile
        File.open(revmapfile, "r:UTF-8") do |f|
          $logger.info("loading revision map #{revmapfile}")

          revmap = f.each_line
                    .map { |line| line.split(/\s+\|\s+/) }
                    .map { |rev, sha, _| [rev.gsub(/^r/, ""), sha] }.to_h # remove leading "r" if present
        end
      end

      revmap
    end

    def interested_in_change?(kind, newvalue)
      !(%w[keywords cc reporter version].include?(kind) ||
        (kind == "comment" && (newvalue.nil? || newvalue.lstrip.empty?)))
    end

    def mock_ticket_details(ticket_id)
      summary = if @filter_applied
                  "Not available in trac #{ticket_id}"
                else
                  "DELETED in trac #{ticket_id}"
                end
      {
        id: ticket_id,
        summary: summary,
        time: Time.now.to_i,
        status: "closed",
        reporter: "tractive"
      }
    end
  end
end
