# frozen_string_literal: true

module Tractive
  class TicketChange < Sequel::Model(:ticket_change)
    many_to_one :ticket, key: :ticket
  end
end
