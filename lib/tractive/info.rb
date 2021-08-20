module Tractive
  class Info
    def initialize(db)
      @db = db
    end

    def print
      users = [
          @db['select distinct reporter from ticket'].map { |r| r[:reporter] },
          @db['select distinct owner from ticket'].map { |r| r[:owner] },
          @db['select distinct author from ticket_change'].map { |r| r[:author] },
          @db["select distinct newvalue from ticket_change where field=\'reporter\'"].map { |r| r[:reporter] },
          @db['select distinct author   from revision'].map { |r| r[:author] },
          @db['select distinct author   from report'].map { |r| r[:author] },
          @db['select distinct author   from attachment'].map { |r| r[:author] }
      ].flatten.uniq.compact

      milestones  = @db['select name, name, due, completed, description  from milestone'].all.map { |i| [i[:name], i] }
      types       = @db['select distinct type        from ticket'].map { |r| r[:type] }.compact
      components  = @db['select distinct component   from ticket'].map { |r| r[:component] }.compact
      resolutions = @db['select distinct resolution  from ticket'].map { |r| r[:resolution] }.compact
      severity    = @db['select distinct severity    from ticket'].map { |r| r[:severity] }.compact
      priorities  = @db['select distinct priority    from ticket'].map { |r| r[:priority] }.compact
      tracstates  = @db['select distinct status      from ticket'].map { |r| r[:status] }.compact

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
