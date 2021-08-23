module Tractive
  class Attachment < Sequel::Model(:attachment)
    dataset_module do
      def tickets_attachments
        filter(type: 'ticket')
      end
    end
  end
end
