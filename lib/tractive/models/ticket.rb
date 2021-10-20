# frozen_string_literal: true

module Tractive
  class Ticket < Sequel::Model(:ticket)
    one_to_many :changes, class: Tractive::TicketChange, key: :ticket
    one_to_many :attachments, class: Attachment, key: :id, conditions: { type: "ticket" }

    dataset_module do
      def for_migration(start_ticket, filterout_closed, filter_options)
        tickets = order(:id)
                  .where { id >= start_ticket }
                  .filter_column(filter_options)

        tickets = tickets.exclude(status: "closed") if filterout_closed

        tickets
      end

      def filter_column(options)
        return self if options.nil? || options.values.compact.empty?

        case options[:operator].downcase
        when "like"
          where { Sequel.like(options[:column_name].to_sym, options[:column_value]) }
        when "not like"
          where { ~Sequel.like(options[:column_name].to_sym, options[:column_value]) }
        else
          where { Sequel.lit("#{options[:column_name]} #{options[:operator]} '#{options[:column_value]}'") }
        end
      end
    end

    def all_changes
      # combine the changes and attachment table results and sort them by date
      change_arr = changes + attachments
      change_arr.sort_by { |change| change[:time] }
    end
  end
end
