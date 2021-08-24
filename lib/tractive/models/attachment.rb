module Tractive
  class Attachment < Sequel::Model(:attachment)
    dataset_module do
      where(:tickets_attachments, type: 'ticket')
      select(:for_export, :id, :filename)
    end
  end
end
