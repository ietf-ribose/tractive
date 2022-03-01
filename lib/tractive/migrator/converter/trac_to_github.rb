# frozen_string_literal: true

module Migrator
  module Converter
    class TracToGithub
      attr_reader :comments_map

      def initialize(args)
        @comments_map = {}

        @trac_ticket_base_url = args[:cfg]["trac"]["ticketbaseurl"]
        @attachurl            = args[:opts][:attachurl] || args[:cfg].dig("ticket", "attachments", "url")
        @changeset_base_url   = args[:cfg]["trac"]["changeset_base_url"] || ""
        @singlepost           = args[:opts][:singlepost]
        @labels_cfg           = args[:cfg]["labels"].transform_values(&:to_h)
        @milestonesfromtrac   = args[:cfg]["milestones"]
        @users                = args[:cfg]["users"].to_h
        @trac_mails_cache     = {}
        @repo                 = args[:cfg]["github"]["repo"]
        @client               = GithubApi::Client.new(access_token: args[:cfg]["github"]["token"])
        @wiki_attachments_url = args[:cfg].dig("wiki", "attachments", "url")
        @revmap_file_path     = args[:opts][:revmapfile] || args[:cfg]["revmap_path"]
        @make_owners_label    = args[:opts]["make-owners-labels"] || args[:cfg]["make_owners_labels"]
        @attachment_options   = {
          url: @attachurl,
          hashed: args[:cfg].dig("ticket", "attachments", "hashed")
        }

        load_milestone_map
        create_labels_on_github(@labels_cfg["severity"].values)
        create_labels_on_github(@labels_cfg["priority"].values)
        create_labels_on_github(@labels_cfg["tracstate"].values)
        create_labels_on_github(@labels_cfg["component"].values)

        @uri_parser = URI::Parser.new
        @twf_to_markdown = Migrator::Converter::TwfToMarkdown.new(
          @trac_ticket_base_url,
          @attachment_options,
          @changeset_base_url,
          @wiki_attachments_url,
          @revmap_file_path,
          git_repo: @repo, home_page_name: args[:opts]["home-page-name"]
        )
      end

      def compose(ticket)
        body = ""
        closed_time = nil

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

        index = 0
        curr_index = 0
        changes.each do |change|
          kind = change[:field] || "attachment"

          next unless interested_in_change?(kind, change[:newvalue])

          if kind == "comment" || (kind == "attachment" && change[:description] != "")
            @comments_map[curr_index] = index
            curr_index += 1
          end

          index += 1
        end

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
          closed_time = x[:time] if x[:field] == "status" && x[:newvalue] == "closed"
        end

        # we separate labels from badges
        # labels: are changed frequently in the lifecycle of a ticket, therefore are transferred to github lables
        # badges: are basically fixed  and are transferred to a metadata table in the ticket

        badges = Set[]

        badges.add(@labels_cfg.fetch("type", {})[ticket[:type]])
        badges.add(@labels_cfg.fetch("resolution", {})[ticket[:resolution]])
        badges.add(@labels_cfg.fetch("version", {})[ticket[:version]])

        labels.add(@labels_cfg.fetch("severity", {})[ticket[:severity]])
        labels.add(@labels_cfg.fetch("priority", {})[ticket[:priority]])
        labels.add(@labels_cfg.fetch("tracstate", {})[ticket[:status]])
        labels.add(@labels_cfg.fetch("component", {})[ticket[:component]])

        labels.delete(nil)

        keywords = ticket[:keywords]&.split(",") || []
        keywords.each do |keyword|
          badges.add(@labels_cfg.fetch("keywords", {})[keyword.strip.gsub(" ", "_")])
        end

        # If the field is not set, it will be nil and generate an unprocessable json

        milestone = @milestonemap[ticket[:milestone]]

        # compute footer
        footer = "_Issue migrated from #{trac_ticket_link(ticket)} at #{Time.now}_"

        # compute badgetabe
        #

        github_assignee = map_assignee(ticket[:owner])

        unless github_assignee.nil? || github_assignee.empty?
          if @make_owners_label
            labels.add("name" => "owner:#{github_assignee}")
          else
            badges.add("owner:#{github_assignee}")
          end
        end

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
        labels = labels.map { |label| label["name"] }

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
          github_owner = @users[owner]["username"]
          $logger.debug("..owner in trac: #{owner}")
          $logger.debug("..assignee in GitHub: #{github_owner}")
          issue["assignee"] = github_owner
        end

        ### as the assignee stuff is pretty fragile, we do not assign at all
        # issue['assignee'] = github_assignee if github_assignee

        if ticket[:changetime]
          # issue["updated_at"] = format_time(ticket[:changetime])
        end

        if issue["closed"]
          issue["closed_at"] = if closed_time
                                 format_time(closed_time)
                               else
                                 format_time(ticket[:closed_at].to_i)
                               end
        end

        {
          "issue" => issue,
          "comments" => comments
        }
      end

      private

      def map_user(user)
        @users.fetch(user, {})["email"] || user
      end

      def map_assignee(user)
        @users.fetch(user, {})["email"]
      end

      def load_milestone_map
        read_milestones_from_github

        newmilestonekeys = @milestonesfromtrac.keys - @milestonemap.keys

        newmilestonekeys.each do |milestonelabel|
          milestone = {
            "title" => milestonelabel.to_s,
            "state" => @milestonesfromtrac[milestonelabel][:completed].to_i.zero? ? "open" : "closed",
            "description" => @milestonesfromtrac[milestonelabel][:description] || "no description in trac",
            "due_on" => "2012-10-09T23:39:01Z"
          }
          due                 = @milestonesfromtrac[milestonelabel][:due]
          milestone["due_on"] = Time.at(due / 1_000_000).strftime("%Y-%m-%dT%H:%M:%SZ") if due

          $logger.info "creating #{milestone}"

          @client.create_milestone(@repo, milestone)
        end

        read_milestones_from_github
        nil
      end

      def read_milestones_from_github
        milestonesongithub = @client.milestones(@repo, { state: "all",
                                                         sort: "due_on",
                                                         direction: "desc" })
        @milestonemap = milestonesongithub.map { |i| [i["title"], i["number"]] }.to_h
        nil
      end

      def create_labels_on_github(labels)
        return if labels.nil? || labels.empty?

        page = 1
        existing_labels = []
        result = @client.labels(@repo, per_page: 100, page: page).map { |label| label["name"] }

        until result.empty?
          existing_labels += result
          page += 1
          result = @client.labels(@repo, per_page: 100, page: page).map { |label| label["name"] }
        end

        new_labels = labels.reject { |label| existing_labels.include?(label["name"]&.strip) }

        new_labels.each do |label|
          params = { name: label["name"] }
          params["color"] = label["color"] unless label["color"].nil?

          @client.create_label(@repo, params)
          $logger.info("Created label: #{label["name"]}")
        end
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
        when "owner", "status", "title", "resolution", "priority", "component", "type", "severity", "platform", "milestone", "keywords"
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
            text += @twf_to_markdown.convert(body, id: meta[:ticket])
          end

        when "comment"
          body      = meta[:newvalue]
          changeset = body.match(/In \[changeset:"(\d+)/).to_a[1]
          text += if changeset
                    # changesethash = @revmap[changeset]
                    "_committed #{Tractive::Utilities.map_changeset(changeset, @revmap, @changeset_base_url)}_"
                  else
                    "_commented_\n\n"
                  end

          text += "\n___\n" unless append
          text += @twf_to_markdown.convert(body, id: meta[:ticket]) if body

        when "attachment"
          text += "_uploaded file "
          name = meta[:filename]
          body = meta[:description]
          if @attachurl
            url = @uri_parser.escape("#{@attachurl}/#{Tractive::Utilities.attachment_path(meta[:id], name, @attachment_options)}")
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
          text += "changed #{kind} which not transferred by tractive"
        end

        {
          "body" => text,
          "created_at" => format_time(meta[:time])
        }
      end

      # returns the author mail if found, otherwise author itself
      def trac_mail(author)
        return @trac_mails_cache[author] if @trac_mails_cache.key?(author)

        # tries to retrieve the email from trac db
        data = Tractive::Session.select(:value).where(Sequel.lit('name = "email" AND sid = ?', author))
        return (@trac_mails_cache[author] = data.first[:value]) if data.count == 1

        (@trac_mails_cache[author] = author) # not found
      end

      # Format time for github API
      def format_time(time)
        time = Time.at(time / 1e6, time % 1e6)
        time.strftime("%FT%TZ")
      end

      def interested_in_change?(kind, newvalue)
        !(%w[cc reporter version].include?(kind) ||
          (kind == "comment" && (newvalue.nil? || newvalue.lstrip.empty?)))
      end

      def trac_ticket_link(ticket)
        return "trac:#{ticket[:id]}" unless @trac_ticket_base_url

        "[trac:#{ticket[:id]}](#{@trac_ticket_base_url}/#{ticket[:id]})"
      end
    end
  end
end
