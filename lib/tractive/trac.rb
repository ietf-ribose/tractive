module Tractive
  class Trac
    attr_reader :tickets, :changes, :sessions, :attachments, :subtickets

    def initialize(db)
      $logger.info('loading tickets')
      @db          = db
      @tickets     = @db[:ticket]
      @subtickets  = @db[:subtickets]
      @changes     = @db[:ticket_change]
      @sessions    = @db[:session_attribute]
      @attachments = @db[:attachment]
    end

    # produce an shell script to be invoked
    # within the tracd container to export the attachmets
    def generate_attachment_exporter(cfg)
      outfile   = cfg.dig("attachments", "export_script")
      outfolder = cfg.dig("attachments", "export_folder")

      raise("mising attachements/export_script entry in configuration") unless outfile
      raise("mising attachements/export_folder entry in configuration") unless outfolder

      attachments   = @db['select id, filename from attachment where type="ticket"']
      exportcommads = attachments.map do |attachment|
        %Q{mkdir -p #{outfolder}/#{attachment[:id]}
        trac-admin /trac attachment export ticket:#{attachment[:id]} '#{attachment[:filename]}' > '#{outfolder}/#{attachment[:id]}/#{attachment[:filename]}'}
      end

      File.open(outfile, "w") do |f|
        f.puts ("mkdir -p #{outfolder}")
        f.puts (exportcommads.join("\n"))
      end

      $logger.info "created attachment exporter in #{outfile}"
    end

    def info

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

      def _mkhash(prefix, array)
        Hash[array.map { |i| [i, "#{prefix}#{i}"] }]
      end

      result = {
        "users"      => _mkhash("", users),
        "milestones" => Hash[milestones],
        "labels"     => {
          "type"       => _mkhash("type_", types),
          "component"  => _mkhash("component_", components),
          "resolution" => _mkhash("resolution_", resolutions),
          "severity"   => _mkhash("severity", severity),
          "priority"   => _mkhash("priority_", priorities),
          "tracstate"  => _mkhash('tracstate_', tracstates)
        }
      }

      # here we use puts (not logger) as we redirect the ymal fo a file
      puts result.to_yaml
    end

  end
end
