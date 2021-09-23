# frozen_string_literal: true

module Migrator
  class Engine
    module MigrateToFile
      def migrate_to_file
        Tractive::GracefulQuit.enable
        migrate_tickets_to_file(@start_ticket, @filter_closed)
      rescue RuntimeError => e
        $logger.error e.message
      end

      private

      # Creates github issues for trac tickets.
      def migrate_tickets_to_file(start_ticket, filterout_closed)
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

            ticket = mock_ticket_details(ticket_id)
          end

          raise("tickets out of sync #{ticket_id} - #{ticket[:id]}") if ticket[:id] != ticket_id

          next if filterout_closed && (ticket[:status] == "closed")

          Tractive::GracefulQuit.check("quitting after processing ticket ##{@last_created_issue}") do
            @output_file.puts "}"
          end

          $logger.info(%{creating issue for trac #{ticket[:id]} "#{ticket[:summary]}" (#{ticket[:reporter]})})
          # API details: https://gist.github.com/jonmagic/5282384165e0f86ef105
          request = compose_issue(ticket)

          @output_file.puts @delimiter
          @output_file.puts({ @current_ticket_id => request }.to_json[1...-1])
          @delimiter = "," if @delimiter != ","
          response = { "status" => "added to file", "issue_url" => "/#{ticket[:id]}" }

          $logger.info("Status: #{response["status"]}")

          issue_id = response["issue_url"].match(/\d+$/).to_s.to_i
          $logger.info("created issue ##{issue_id} for trac ticket #{ticket[:id]}")

          @last_created_issue = ticket[:id]
        end

        @output_file.puts "}"
      end
    end
  end
end
