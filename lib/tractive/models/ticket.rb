# frozen_string_literal: true

module Tractive
  class Ticket < Sequel::Model(:ticket)
    one_to_many :changes, class: TicketChange, key: :ticket
    one_to_many :attachments, class: Attachment, key: :id, conditions: { type: "ticket" }

    def all_changes
      # combine the changes and attachment table results and sort them by date
      change_arr = changes + attachments
      change_arr.sort_by { |change| change[:time] }
    end
  end
end
