module Tractive
  class Trac
    attr_reader :tickets, :changes, :sessions, :attachments, :subtickets

    def initialize(db)
      $logger.info('loading tickets')
      @db          = db
      @tickets     = Ticket
      @subtickets  = Subticket
      @changes     = Change
      @sessions    = Session
      @attachments = Attachment
    end
  end
end
