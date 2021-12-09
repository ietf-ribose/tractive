# frozen_string_literal: true

module Tractive
  class Attachment < Sequel::Model(:attachment)
    dataset_module do
      where(:tickets_attachments, type: "ticket")
      where(:wiki_attachments, type: "wiki")
      select(:for_export, :id, :filename)
    end
  end
end
