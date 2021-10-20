# frozen_string_literal: true

module Tractive
  class Info
    def print
      $logger.info result_hash.to_yaml
    end

    private

    def result_hash
      users = [
        Ticket.distinct.select(:reporter).select_map(:reporter),
        Ticket.distinct.select(:owner).select_map(:owner),
        TicketChange.distinct.select(:author).select_map(:author),
        TicketChange.distinct.select(:newvalue).where(field: "reporter").select_map(:newvalue),
        Revision.distinct.select(:author).select_map(:author),
        Report.distinct.select(:author).select_map(:author),
        Attachment.distinct.select(:author).select_map(:author)
      ].flatten.uniq.compact

      milestones = {}
      Milestone.each { |r| milestones[r.name] = r.to_hash }

      types       = Ticket.distinct.select(:type).select_map(:type).compact
      components  = Ticket.distinct.select(:component).select_map(:component).compact
      resolutions = Ticket.distinct.select(:resolution).select_map(:resolution).compact
      severity    = Ticket.distinct.select(:severity).select_map(:severity).compact
      priorities  = Ticket.distinct.select(:priority).select_map(:priority).compact
      tracstates  = Ticket.distinct.select(:status).select_map(:status).compact

      {
        "users" => Utilities.make_each_hash(users, %w[email name username]),
        "milestones" => milestones,
        "labels" => {
          "type" => Utilities.make_hash("type_", types),
          "component" => Utilities.make_hash("component_", components),
          "resolution" => Utilities.make_hash("resolution_", resolutions),
          "severity" => Utilities.make_each_hash(severity, %w[name color]),
          "priority" => Utilities.make_each_hash(priorities, %w[name color]),
          "tracstate" => Utilities.make_each_hash(tracstates, %w[name color])
        }
      }
    end
  end
end
