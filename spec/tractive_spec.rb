# frozen_string_literal: true

RSpec.describe Tractive do
  it "has a version number" do
    expect(Tractive::VERSION).not_to be nil
  end

  it "has working info command" do
    expect(Tractive::Info.new(@db).send(:result_hash)).to eq(db_result_hash)
  end

  it "compose correct issue" do
    stub_issues_request
    stub_milestone_map_request
    ticket = Tractive::Ticket.find(id: 1)

    expect(Tractive::Migrator.new(options_for_migrator).send(:compose_issue, ticket)).to eq(ticket_compose_hash(ticket))
  end

  def db_result_hash
    {
      "users" => { "user" => "user", "somebody" => "somebody" },
      "milestones" => milestones_hash,
      "labels" => {
        "type" => { "defect" => "type_defect", "enhancement" => "type_enhancement" },
        "component" => { "component1" => "component_component1", "component2" => "component_component2" },
        "resolution" => {},
        "severity" => {},
        "priority" => { "major" => "priority_major", "minor" => "priority_minor" },
        "tracstate" => { "assigned" => "tracstate_assigned", "new" => "tracstate_new" }
      }
    }
  end

  def options_for_migrator
    {
      opts: { "config" => "trac-hub.config.yaml", "dryrun" => true },
      cfg: { "trac" => { "database" => "mysql2://root:password@127.0.0.1:3306/foobar" },
             "github" => { "repo" => "hassanakbar4/foobar", "token" => "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" },
             "revmapfile" => "./foobar-revmap.txt",
             "users" => { "hassanakbar4" => "hassanakbar4" },
             "milestones" => milestones_hash,
             "labels" =>
          { "type" => { "defect" => "type_defect" },
            "component" => { "component1" => "component_component1" },
            "resolution" => { "invalid" => "resolution_invalid" },
            "severity" => { "blocker" => "#high", "critical" => "#critical", "major" => "#major", "minor" => "#minor", "trivial" => "#trivial" },
            "priority" => { "critical" => "priority_critical", "major" => "priority_major" },
            "tracstate" => { "new" => "tracstate_new", "closed" => "tracstate_closed" } },
             "attachments" => { "url" => "http://localhost:81/raw-attachment/ticket", "export_folder" => "./attachments", "export_script" => ".//attachments.sh" } },
      db: @db
    }
  end

  def milestones_hash
    {
      "milestone1" => { name: "milestone1", due: 0, completed: 0, description: nil },
      "milestone2" => { name: "milestone2", due: 0, completed: 0, description: nil },
      "milestone3" => { name: "milestone3", due: 0, completed: 0, description: nil },
      "milestone4" => { name: "milestone4", due: 0, completed: 0, description: nil }
    }
  end

  def ticket_compose_hash(ticket)
    {
      "comments" => [],
      "issue" => {
        "body" => "`component_component1` `type_defect`deleted Ticket\n\n___\n\n\nchanged initial which not transferred by trac-hub\n\n___\nIssue migrated from trac:1 at #{Time.now}",
        "labels" => ["priority_major", "tracstate_new", "owner:"],
        "milestone" => nil,
        "title" => "Ticket 1",
        "closed" => false,
        "created_at" => format_time(ticket[:time])
      }
    }
  end

  def stub_issues_request
    stub_request(:get, %r{https://api.github.com/repos/hassanakbar4/foobar/issues\?*})
      .to_return(status: 200, body: "[]", headers: {})
  end

  def stub_milestone_map_request
    stub_request(:get, %r{https://api.github.com/repos/hassanakbar4/foobar/milestones\?*})
      .to_return(status: 200,
                 body: "[{ \"title\": \"milestone4\", \"number\": 4 }, { \"title\": \"milestone3\", \"number\": 3 },{ \"title\": \"milestone2\", \"number\": 2 },{ \"title\": \"milestone1\", \"number\": 1 } ]",
                 headers: {})
  end

  # TODO: Need to remove this when refactoring migrator class
  def format_time(time)
    time = Time.at(time / 1e6, time % 1e6)
    time.strftime("%FT%TZ")
  end
end
