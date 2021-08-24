module Tractive
  class Info
    def initialize(db)
      @db = db
    end

    def print
      users = [
        Ticket.distinct(:reporter).select_map(:reporter),
        Ticket.distinct(:owner).select_map(:owner),
        TicketChange.distinct(:author).select_map(:author),
        TicketChange.distinct(:newvalue).where(field: 'reporter').select_map(:newvalue),
        Revision.distinct(:author).select_map(:author),
        Report.distinct(:author).select_map(:author),
        Attachment.distinct(:author).select_map(:author)
      ].flatten.uniq.compact

      milestones  = {}
      Milestone.each { |r| milestones[r.name] = r.to_hash }

      types       = Ticket.distinct(:type).select_map(:type).compact
      components  = Ticket.distinct(:component).select_map(:component).compact
      resolutions = Ticket.distinct(:resolution).select_map(:resolution).compact
      severity    = Ticket.distinct(:severity).select_map(:severity).compact
      priorities  = Ticket.distinct(:priority).select_map(:priority).compact
      tracstates  = Ticket.distinct(:status).select_map(:status).compact

      result = {
        "users"      => Utilities.make_hash("", users),
        "milestones" => milestones,
        "labels"     => {
          "type"       => Utilities.make_hash("type_", types),
          "component"  => Utilities.make_hash("component_", components),
          "resolution" => Utilities.make_hash("resolution_", resolutions),
          "severity"   => Utilities.make_hash("severity", severity),
          "priority"   => Utilities.make_hash("priority_", priorities),
          "tracstate"  => Utilities.make_hash('tracstate_', tracstates)
        }
      }

      $logger.info result.to_yaml
    end
  end
end
