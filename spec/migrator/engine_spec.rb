# frozen_string_literal: true

RSpec.describe Migrator::Engine do
  before(:each) do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request

    time_now = Time.now
    allow(Time).to receive(:now).and_return(time_now)
  end

  it "should output composed tickets in file" do
    stub_get_labels_request
    stub_create_labels_request

    buffer = StringIO.new
    filename = "#{Dir.pwd}/dryrun_out.json"
    allow(File).to receive(:new).with(filename, "w+").and_return(buffer)

    converter = Migrator::Converter::TracToGithub.new(options_for_migrator)
    migrator = Migrator::Engine.new(options_for_migrator(dryrun: true, filter: true, columnname: "id", operator: "<", columnvalue: "4"))
    migrator.migrate

    actual_hash = JSON.parse(buffer.string)
    expected_hash = JSON.parse(file_expected_output(migrator, converter))

    expect(actual_hash).to eq(expected_hash)
  end

  it "should compose correct mock ticket" do
    mock_ticket = Migrator::Engine.new(options_for_migrator).send(:mock_ticket_details, 1)

    expect(mock_ticket[:summary]).to eq("DELETED in trac 1")
  end

  it "should compose correct mock ticket when filtering" do
    mock_ticket = Migrator::Engine.new(options_for_migrator(filter: true)).send(:mock_ticket_details, 1)

    expect(mock_ticket[:summary]).to eq("Placeholder issue 1 created to align github issue and trac ticket numbers during migration.")
  end

  it "should generate correct comment body" do
    comments = test_comments
    response = Migrator::Engine.new(options_for_migrator).send(:create_update_comment_params, comments[3], comments, 1)
    expect(response).to eq("_@hassanakbar4_ _commented_\n\n\n___\nReplying to [test/repo#1 (comment:1)](https://github.com/test/repo/issues/1#issuecomment-913628459):")
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
