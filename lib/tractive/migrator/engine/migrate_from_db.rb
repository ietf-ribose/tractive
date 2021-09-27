# frozen_string_literal: true

module Migrator
  class Engine
    module MigrateFromDb
      def migrate_from_db
        Tractive::GracefulQuit.enable
        migrate_tickets_from_db(@start_ticket, @filter_closed)
      rescue RuntimeError => e
        $logger.error e.message
      end

      private

      # Creates github issues for trac tickets.
      def migrate_tickets_from_db(start_ticket, filterout_closed)
        $logger.info("migrating issues")
        # We match the issue title to determine whether an issue exists already.
        tractickets = @trac.tickets
                           .for_migration(start_ticket, filterout_closed, @filter_options)
                           .all

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

            ticket = mock_ticket_details(ticket_id)
          end

          raise("tickets out of sync #{ticket_id} - #{ticket[:id]}") if ticket[:id] != ticket_id

          Tractive::GracefulQuit.check("quitting after processing ticket ##{@last_created_issue}")

          if @safetychecks
            begin
              # issue exists already:
              @client.issue(@repo, ticket[:id])
              $logger.info("found ticket #{ticket[:id]}")
              next
            rescue StandardError
            end
          end

          $logger.info(%{creating issue for trac #{ticket[:id]} "#{ticket[:summary]}" (#{ticket[:reporter]})})
          # API details: https://gist.github.com/jonmagic/5282384165e0f86ef105
          request = Migrator::Converter::TracToGithub.new(@config).compose(ticket)

          response = @client.create_issue(@repo, request)

          if @safetychecks # - it is not really faster if we do not wait for the processing
            while response["status"] == "pending"
              sleep 1
              $logger.info("Checking import status: #{response["id"]}")
              $logger.info("you can manually check: #{response["url"]}")
              response = @client.issue_import_status(@repo, response["id"])
            end

            $logger.info("Status: #{response["status"]}")

            if response["status"] == "failed"
              $logger.error(response["errors"])
              exit 1
            end

            issue_id = response["issue_url"].match(/\d+$/).to_s.to_i

            $logger.info("created issue ##{issue_id} for trac ticket #{ticket[:id]}")

            update_comment_ref(issue_id) if request.to_s.include?("Replying to [comment:")

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
      end

      def update_comment_ref(issue_id)
        comments = @client.issue_comments(@repo, issue_id)
        comments.each do |comment|
          next unless comment["body"].include?("Replying to [comment:")

          body = comment["body"]
          matcher = body.match(/Replying to \[comment:(?<comment_number>\d+).*\]/)
          matched_comment = comments[matcher[:comment_number].to_i - 1]
          body.gsub!(/Replying to \[comment:(\d+).*\]/, "Replying to [#{@repo}##{issue_id} (comment:\\1)](#{matched_comment["html_url"]})")
          @client.update_issue_comment(@repo, comment["id"], body)
        end
      end
    end
  end
end
