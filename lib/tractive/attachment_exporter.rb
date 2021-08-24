require 'fileutils'
require 'open-uri'

module Tractive
  class AttachmentExporter
    def initialize(cfg, db)
      @cfg = cfg
      @db = db
    end

    # produce an shell script to be invoked
    # within the tracd container to export the attachmets
    def generate_script
      outfile   = @cfg.dig("attachments", "export_script")
      outfolder = @cfg.dig("attachments", "export_folder")

      raise("mising attachements/export_script entry in configuration") unless outfile
      raise("mising attachements/export_folder entry in configuration") unless outfolder

      attachments   = Attachment.tickets_attachments.for_export
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

    # export the images from the database into a folder
    def export
      output_dir = @cfg.dig('attachments', 'export_folder') || "#{Dir.pwd}/tmp/trac"
      trac_url = @cfg.dig('attachments', 'url')

      raise("attachments url is required in config.yaml to export attachments.") unless trac_url

      FileUtils.mkdir_p output_dir
      attachments = Attachment.tickets_attachments.for_export

      # using URI::Parser.new because URI.encode raise warning: URI.escape is obsolete
      uri_parser = URI::Parser.new

      attachments.each do |attachment|
        $logger.info "Saving attachments of ticket #{attachment.id}... "
        FileUtils.mkdir_p "#{output_dir}/#{attachment.id}"

        File.open("#{output_dir}/#{attachment.id}/#{attachment.filename}", "wb") do |file|
          file.write URI.open(uri_parser.escape("#{trac_url}/#{attachment.id}/#{attachment.filename}")).read
        end
      end
    end
  end
end
