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
          delete_mocked_tickets
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
              $logger.debug("you can manually check: #{response["url"]}")
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

        delete_mocked_tickets
      end

      def delete_mocked_tickets
        return unless @delete_mocked_tickets

        page = 1
        issues = @client.issues(@repo, { filter: "all",
                                         state: "closed" })
        until issues.empty?
          deleted = false

          issues.each do |issue|
            next if issue["title"] != "Placeholder issue #{issue["number"]} created to align Github issue and trac ticket numbers during migration."

            response = @client.delete_issue(issue["node_id"])

            raise response.data.errors.messages.map { |k, v| "#{k}: #{v}" }.join(", ") if response.data.errors.any?

            deleted = true
            puts "Successfully deleted issue ##{issue["number"]}, Title: #{issue["title"]}"
          end

          page += 1 unless deleted
          issues = @client.issues(@repo, { filter: "all",
                                           state: "closed",
                                           page: page })
        end
      end
    end
  end
end
