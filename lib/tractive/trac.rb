# frozen_string_literal: true

module Tractive
  class Trac
    attr_reader :tickets, :changes, :sessions, :attachments, :wikis

    def initialize(db)
      $logger.info("loading tickets")
      @db          = db
      @tickets     = Ticket
      @changes     = TicketChange
      @sessions    = Session
      @attachments = Attachment
      @wikis       = Wiki
    end
  end
end
