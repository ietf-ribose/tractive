# frozen_string_literal: true

RSpec.describe Migrator::Converter::TracToGithub do
  before :each do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request
    stub_get_labels_request
    stub_create_labels_request

    time_now = Time.now
    allow(Time).to receive(:now).and_return(time_now)
  end

  it "compose correct issue" do
    ticket = Tractive::Ticket.find(id: 3)

    actual_ticket_hash = Migrator::Converter::TracToGithub.new(options_for_migrator).compose(ticket)
    expected_ticket_hash = ticket_compose_hash3(ticket)

    expect(actual_ticket_hash["issue"]).to eq(expected_ticket_hash["issue"])
    expect(actual_ticket_hash["comments"]).to match_array(expected_ticket_hash["comments"])
  end

  it "compose correct issue without assignee" do
    ticket = Tractive::Ticket.find(id: 98)

    actual_ticket_hash = Migrator::Converter::TracToGithub.new(options_for_migrator).compose(ticket)
    expected_ticket_hash = ticket_compose_hash98(ticket)

    expect(actual_ticket_hash["issue"]).to eq(expected_ticket_hash["issue"])
    expect(actual_ticket_hash["comments"]).to match_array(expected_ticket_hash["comments"])
  end

  it "compose correct issue with all comments as single post" do
    ticket = Tractive::Ticket.find(id: 170)

    actual_ticket_hash = Migrator::Converter::TracToGithub.new(options_for_migrator(singlepost: true)).compose(ticket)
    expected_ticket_hash = ticket_compose_hash_with_singlepost(ticket)

    expect(actual_ticket_hash["issue"]).to eq(expected_ticket_hash["issue"])
    expect(actual_ticket_hash["comments"]).to match_array(expected_ticket_hash["comments"])
  end

  it "compose correct issue with attachments as hashed values" do
    ticket = Tractive::Ticket.find(id: 872)

    actual_ticket_hash = Migrator::Converter::TracToGithub.new(options_for_migrator).compose(ticket)
    expected_ticket_hash = ticket_compose_hash872(ticket)

    expect(actual_ticket_hash["issue"]).to eq(expected_ticket_hash["issue"])
    expect(actual_ticket_hash["comments"]).to match_array(expected_ticket_hash["comments"])
  end
end
