module Tractive
  class Info
    def initialize(db)
      @db = db
    end

    def print
      users = [
          @db[:ticket].distinct(:reporter).select_map(:reporter),
          @db[:ticket].distinct(:owner).select_map(:owner),
          @db[:ticket_change].distinct(:author).select_map(:author),
          @db[:ticket_change].distinct(:newvalue).where(field: 'reporter').select_map(:newvalue),
          @db[:revision].distinct(:author).select_map(:author),
          @db[:report].distinct(:author).select_map(:author),
          @db[:attachment].distinct(:author).select_map(:author)
      ].flatten.uniq.compact

      milestones  = @db[:milestone].select(:name, :due, :completed, :description).all.map { |i| [i[:name], i] }

      types       = @db[:ticket].distinct(:type).select_map(:type).compact
      components  = @db[:ticket].distinct(:component).select_map(:component).compact
      resolutions = @db[:ticket].distinct(:resolution).select_map(:resolution).compact
      severity    = @db[:ticket].distinct(:severity).select_map(:severity).compact
      priorities  = @db[:ticket].distinct(:priority).select_map(:priority).compact
      tracstates  = @db[:ticket].distinct(:status).select_map(:status).compact

      result = {
        "users"      => Tractive::Utilities.make_hash("", users),
        "milestones" => Hash[milestones],
        "labels"     => {
          "type"       => Tractive::Utilities.make_hash("type_", types),
          "component"  => Tractive::Utilities.make_hash("component_", components),
          "resolution" => Tractive::Utilities.make_hash("resolution_", resolutions),
          "severity"   => Tractive::Utilities.make_hash("severity", severity),
          "priority"   => Tractive::Utilities.make_hash("priority_", priorities),
          "tracstate"  => Tractive::Utilities.make_hash('tracstate_', tracstates)
        }
      }

      $logger.info result.to_yaml
    end
  end
end
