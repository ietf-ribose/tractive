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
    rescue StandardError => e
      $logger.error(e.message)
      exit(1)
    end
  end
end
