# frozen_string_literal: true

RSpec.describe Tractive::Trac do
  it "counts total attachments" do
    expect(Tractive::Attachment.count).to eq(181)
  end

  it "should fileter attachments by type tickets" do
    expect(Tractive::Attachment.tickets_attachments.select_map(:type).uniq).to eq(["ticket"])
  end

  it "should get id and filename columns only" do
    expect(Tractive::Attachment.for_export.columns).to eq(%i[id filename])
  end
end
