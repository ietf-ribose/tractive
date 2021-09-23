# frozen_string_literal: true

RSpec.describe Tractive::Trac do
  it "counts total tickets" do
    expect(Tractive::Ticket.count).to eq(16)
  end

  it "counts total tickets having `MailArchive` as prefix in component" do
    tickets = Tractive::Ticket.for_migration(10, false, options_for_column_having_prefix("component", "MailArchive"))
    expect(tickets.count).to eq(1)
    expect(tickets.sql).to eq("SELECT * FROM `ticket` WHERE ((`id` >= 10) AND (`component` LIKE 'MailArchive%' ESCAPE '\\')) ORDER BY `id`")
  end

  it "should count total tickets having `medium` priority" do
    tickets = Tractive::Ticket.for_migration(1, false, options_for_column_equal("priority", "medium"))

    expect(tickets.count).to eq(4)
    expect(tickets.sql).to eq("SELECT * FROM `ticket` WHERE ((`id` >= 1) AND (priority = 'medium')) ORDER BY `id`")
  end

  it "returns all changes of a ticket" do
    ticket = Tractive::Ticket.where(id: 3).first

    expect(ticket.all_changes.count).to eq(19)
  end

  def options_for_column_having_prefix(column_name, prefix)
    {
      column_name: column_name,
      operator: "like",
      column_value: "#{prefix}%"
    }
  end

  def options_for_column_equal(column_name, value)
    {
      column_name: column_name,
      operator: "=",
      column_value: value
    }
  end
end
