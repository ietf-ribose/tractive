# frozen_string_literal: true

module Tractive
  class Wiki < Sequel::Model(:wiki)
    set_primary_key :name
    one_to_many :attachments, class: Attachment, key: :id, conditions: { type: "wiki" }

    dataset_module do
      def for_migration
        select(:name, :version, :author, :comment, Sequel.lit("datetime(time/1000000, 'unixepoch')").as(:fixeddate), :text).order(:name, :version)
      end

      def latest_versions
        select(:name, :version, :text).group(:name).having { version =~ MAX(version) }
      end
    end
  end
end
