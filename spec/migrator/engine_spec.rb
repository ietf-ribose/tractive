# frozen_string_literal: true

RSpec.describe Migrator::Engine do
  it "should output composed tickets in file" do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request

    buffer = StringIO.new
    filename = "#{Dir.pwd}/dryrun_out.json"
    allow(File).to receive(:new).with(filename, "w+").and_return(buffer)

    converter = Migrator::Converter::TracToGithub.new(options_for_migrator)
    migrator = Migrator::Engine.new(options_for_migrator(dryrun: true, filter: true, columnname: "id", operator: "<", columnvalue: "4"))
    migrator.migrate

    expect(buffer.string).to eq(file_expected_output(migrator, converter))
  end

  it "should compose correct mock ticket" do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request

    mock_ticket = Migrator::Engine.new(options_for_migrator).send(:mock_ticket_details, 1)

    expect(mock_ticket[:summary]).to eq("DELETED in trac 1")
  end

  it "should compose correct mock ticket when filtering" do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request

    mock_ticket = Migrator::Engine.new(options_for_migrator(filter: true)).send(:mock_ticket_details, 1)

    expect(mock_ticket[:summary]).to eq("Not available in trac 1")
  end

  def file_expected_output(migrator, converter)
    ticket = Tractive::Ticket.find(id: 3)
    "{" \
      "\n\"1\":#{converter.compose(migrator.send(:mock_ticket_details, 1)).to_json}\n," \
      "\n\"2\":#{converter.compose(migrator.send(:mock_ticket_details, 2)).to_json}\n," \
      "\n\"3\":#{ticket_compose_hash3(ticket).to_json}" \
      "\n}\n"
  end
end
