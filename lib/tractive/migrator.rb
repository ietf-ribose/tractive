# frozen_string_literal: true

module Tractive
  class Migrator
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

      @trac  = Tractive::Trac.new(db)
      @repo  = github["repo"]
      @token = github["token"]

      @milestonesfromtrac = milestones

      @users = users.to_h

      @labels_cfg        = labels.transform_values(&:to_h)
      @ticket_to_issue   = {}
      @trac_mails_cache  = {}
      @mockdeleted       = mockdeleted
      @tracticketbaseurl = tracticketbaseurl

      $logger.debug("Get highest in #{@repo}")
      issues = JSON.parse(RestClient.get(
                            "https://api.github.com/repos/#{@repo}/issues",
                            { "Authorization" => "token #{@token}",
                              params: {
                                filter: "all",
                                state: "all",
                                sort: "created",
                                direction: "desc"
                              } }
                          ))
      @last_created_issue = issues.empty? ? 0 : issues[0]["number"].to_i

      $logger.info("created issue on GitHub is '#{@last_created_issue}' #{issues.count}")

      load_milestone_map

      dry_run_output_file = args[:cfg][:dry_run_output_file] || "#{Dir.pwd}/dryrun_out.json"

      @dry_run          = args[:opts][:dryrun]
      @output_file      = File.new(dry_run_output_file, "w+")
      @delimiter        = "["
      @revmap           = load_revmap_file(args[:opts][:revmapfile] || args[:cfg]["revmapfile"])
      @attachurl        = attachurl
      @singlepost       = singlepost
      @safetychecks     = safetychecks
      @start_ticket     = (start_ticket || @last_created_issue + 1).to_i
      @filter_closed    = filter_closed
      @uri_parser = URI::Parser.new
    end

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
        JSON.parse(RestClient.post(
                     "https://api.github.com/repos/#{@repo}/milestones",
                     milestone.to_json,
                     { "Authorization" => "token #{@token}",
                       "Content-Type" => "application/json",
                       "Accept" => "application/vnd.github.golden-comet-preview+json" }
                   ))
      end

      read_milestones_from_github

      $logger.info("Last created issue on GitHub is '#{@last_created_issue}'")
      nil
    end

    def map_user(user)
      @users[user] || user
    end

    def map_assignee(user)
      @users[user]
    end

    def migrate
      GracefulQuit.enable
      migrate_tickets(@start_ticket, @filter_closed)
    rescue RuntimeError => e
      $logger.error e.message
    end

    private

    def read_milestones_from_github
      milestonesongithub = JSON.parse(RestClient.get(
                                        "https://api.github.com/repos/#{@repo}/milestones?per_page=100",
                                        { "Authorization" => "token #{@token}",
                                          params: {
                                            state: "all",
                                            sort: "due_on",
                                            direction: "desc"
                                          } }
                                      ))
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

    # returns the git commit hash for a specified revision (using revmap hash)
    def map_changeset(str)
      if @revmap&.key?(str)
        "[r#{str}](../commit/#{@revmap[str]}) #{@revmap[str]}"
      else
        str
      end
    end

    def map_image(str)
      %{![#{str}](#{@attachurl}/#{@current_ticket_id}/#{str}) }
      # %Q{>>**insert-missing-image: (#{str}**)}
    end

    # Format time for github API
    def format_time(time)
      time = Time.at(time / 1e6, time % 1e6)
      time.strftime("%FT%TZ")
    end

    # Creates github issues for trac tickets.
    def migrate_tickets(start_ticket, filterout_closed)
      $logger.info("migrating issues")
      # We match the issue title to determine whether an issue exists already.
      tractickets = @trac.tickets.order(:id).where { id >= start_ticket }.all
      begin
        lasttracid = tractickets.last[:id]
      rescue StandardError
        raise("trac has no ticket #{start_ticket}")
      end

      (start_ticket.to_i..lasttracid).each do |ticket_id|
        ticket = tractickets.select { |i| i[:id] == ticket_id }.first

        @current_ticket_id = ticket_id # used to build filename for attachments

        if ticket.nil?
          next unless @mockdeleted

          ticket = {
            id: ticket_id,
            summary: "DELETED in trac #{ticket_id}",
            time: Time.now.to_i,
            status: "closed",
            reporter: "trac-hub"
          }
        end

        raise("tickets out of sync #{ticket_id} - #{ticket[:id]}") if ticket[:id] != ticket_id

        next if filterout_closed && (ticket[:status] == "closed")

        GracefulQuit.check("quitting after processing ticket ##{@last_created_issue}") do
          @output_file.puts "]"
        end

        if @safetychecks
          begin
            # issue exists already:
            JSON.parse(RestClient.get(
                         "https://api.github.com/repos/#{@repo}/issues/#{ticket[:id]}",
                         { "Authorization" => "token #{@token}" }
                       ))
            $logger.info("found ticket #{ticket[:id]}")
            next
          rescue StandardError
          end
        end

        $logger.info(%{creating issue for trac #{ticket[:id]} "#{ticket[:summary]}" (#{ticket[:reporter]})})
        # API details: https://gist.github.com/jonmagic/5282384165e0f86ef105
        request = compose_issue(ticket)

        if @dry_run
          @output_file.puts @delimiter
          @output_file.puts request.to_json
          @delimiter = "," if @delimiter == "["
          response = { "status" => "added to file", "issue_url" => "/#{ticket[:id]}" }
        else
          response = JSON.parse(
            RestClient.post(
              "https://api.github.com/repos/#{@repo}/import/issues",
              request.to_json,
              {
                "Authorization" => "token #{@token}",
                "Content-Type" => "application/json",
                "Accept" => "application/vnd.github.golden-comet-preview+json"
              }
            )
          )
        end

        if @safetychecks # - it is not really faster if we do not wait for the processing
          while response["status"] == "pending"
            sleep 1
            $logger.info("Checking import status: #{response["id"]}")
            $logger.info("you can manually check: #{response["url"]}")
            response = JSON.parse(RestClient.get(response["url"], {
                                                   "Authorization" => "token #{@token}",
                                                   "Accept" => "application/vnd.github.golden-comet-preview+json"
                                                 }))
          end

          $logger.info("Status: #{response["status"]}")

          if response["status"] == "failed"
            $logger.error(response["errors"])
            exit 1
          end

          issue_id = response["issue_url"].match(/\d+$/).to_s.to_i

          $logger.info("created issue ##{issue_id} for trac ticket #{ticket[:id]}")

          # assert correct issue number
          if issue_id != ticket[:id]
            $logger.warn("mismatch issue ##{issue_id} for ticket #{ticket[:id]}")
            exit 1
          end
        else
          # to allow manual verification:
          $logger.info(response["url"])
        end
        @last_created_issue = ticket[:id]
      end

      @output_file.puts "]"
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
      # combine the changes and attachment table results and sort them by date
      changes = @trac.changes.where(ticket: ticket[:id]).collect.to_a
      changes += @trac.attachments.where(type: "ticket", id: ticket[:id]).collect.to_a
      changes = changes.sort_by { |x| x[:time] }

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
        "   |    by #{trac_mail(changes.first[:author])}"
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
          text += markdownify(body)
        end

      when "comment"
        body      = meta[:newvalue]
        changeset = body.match(/In \[changeset:"(\d+)/).to_a[1]
        text += if changeset
                  # changesethash = @revmap[changeset]
                  "_committed #{map_changeset(changeset)}_"
                else
                  "_commented_\n\n"
                end

        text += "\n___\n" unless append
        text += markdownify(body) if body
        return nil if body.nil? || body.lstrip.empty?

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

      when "keywords", "cc", "reporter", "version"
        # don't care
        return nil

      else
        # this should not happen
        text += "changed #{kind} which not transferred by trac-hub"
      end

      {
        "body" => text,
        "created_at" => format_time(meta[:time])
      }
    end

    def markdownify(str)
      # Line endings
      str.gsub!("\r\n", "\n")
      # CommitTicketReference
      str.gsub!(/\{\{\{\n(#!CommitTicketReference .+?)\}\}\}/m, '\1')
      str.gsub!(/#!CommitTicketReference .+\n/, "")
      # Code
      str.gsub!(/\{\{\{([^\n]+?)\}\}\}/, '`\1`')
      str.gsub!(/\{\{\{(.+?)\}\}\}/m, '```\1```')
      str.gsub!(/(?<=```)#!/m, "")
      # Headings
      str.gsub!(/====\s(.+?)\s====/, '#### \1')
      str.gsub!(/===\s(.+?)\s===/, '### \1')
      str.gsub!(/==\s(.+?)\s==/, '## \1')
      str.gsub!(/=\s(.+?)\s=/, '# \1')
      # Links
      str.gsub!(/\[(http[^\s\[\]]+)\s([^\[\]]+)\]/, '[\2](\1)')
      str.gsub!(/!(([A-Z][a-z0-9]+){2,})/, '\1')
      # Font styles
      str.gsub!(/'''(.+?)'''/, '**\1**')
      str.gsub!(/''(.+?)''/, '*\1*')
      str.gsub!(%r{[^:]//(.+?[^:])//}, '_\1_')
      # Lists
      str.gsub!(/(^\s+)\*/, '\1-')
      str.gsub!(/(^\s+)(\d)\./, '\1\2.')
      # Changeset
      str.gsub!(%r{https?://svnweb.cern.ch/trac/madx/changeset/(\d+)/?}, '[changeset:\1]')
      str.gsub!(/\[changeset:"r(\d+)".*\]/, '[changeset:\1]')
      str.gsub!(/\[changeset:r(\d+)\]/, '[changeset:\1]')
      str.gsub!(/\br(\d+)\b/) { map_changeset(Regexp.last_match[1]) }
      str.gsub!(/\[changeset:"(\d+)".*\]/) { map_changeset(Regexp.last_match[1]) }
      str.gsub!(/\[changeset:"(\d+).*\]/) { map_changeset(Regexp.last_match[1]) }

      # image reference
      str.gsub!(/\[\[Image\(([^)]+)\)\]\]/) { map_image(Regexp.last_match[1]) }

      # replace a full ticket id with the github short refrence
      if @tracticketbaseurl
        baseurlpattern = @tracticketbaseurl.gsub("/", "\\/")
        str.gsub!(%r{#{baseurlpattern}/(\d+)}) { "ticket:#{Regexp.last_match[1]}  " }
      end

      # Ticket
      str.gsub!(/ticket:(\d+)/, '#\1')
      # set the body as a comment
      # str.gsub!("\n", "\n> ")
      # str = "> #{str}"
      str
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
  end
end
