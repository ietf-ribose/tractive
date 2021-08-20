module Tractive
  class Trac
    attr_reader :tickets, :changes, :sessions, :attachments, :subtickets

    def initialize(db)
      $logger.info('loading tickets')
      @db          = db
      @tickets     = Tractive::Model::Ticket
      @subtickets  = Tractive::Model::Subticket
      @changes     = Tractive::Model::Change
      @sessions    = Tractive::Model::Session
      @attachments = Tractive::Model::Attachment
    end
  end
end
