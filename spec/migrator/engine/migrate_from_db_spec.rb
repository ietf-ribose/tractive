# frozen_string_literal: true

RSpec.describe Migrator::Engine::MigrateFromDb do
  before(:all) do
    stub_milestone_map_request
    stub_milestone_request
    stub_graphql_schema_request

    GithubApi::GraphQlClient.add_constants("mock_token")
  end

  describe "#can_delete_mocked_tickets?" do
    before(:each) do
      stub_issues_request
    end

    it "will return false based on options" do
      migrator = Migrator::Engine.new(options_for_migrator)

      expect(migrator.send(:can_delete_mocked_tickets?)).to be_falsy
    end

    it "will return true based on options" do
      options = options_for_migrator
      options[:cfg]["ticket"]["delete_mocked"] = true

      migrator = Migrator::Engine.new(options)

      expect(migrator.send(:can_delete_mocked_tickets?)).to be_truthy
    end
  end

  describe "#delete_mocked_tickets" do
    it "will raise error if delete is not successful" do
      stub_issues_request_for_delete_mocked_issues
      stub_delete_issue_and_return_errors

      migrator = Migrator::Engine.new(options_for_migrator)

      expect { migrator.send(:delete_mocked_tickets) }.to raise_error(StandardError)
    end
  end
end
