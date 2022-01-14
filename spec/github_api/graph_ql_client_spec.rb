# frozen_string_literal: true

RSpec.describe GithubApi::GraphQlClient do
  describe ".add_constants" do
    it "will set required constants and token" do
      stub_graphql_schema_request

      expect { GithubApi::GraphQlClient::Schema }.to raise_error(NameError)
      expect { GithubApi::GraphQlClient::Client }.to raise_error(NameError)
      expect { GithubApi::GraphQlClient::DeleteIssueQuery }.to raise_error(NameError)
      expect(GithubApi::GraphQlClient::HttpAdapter.headers("")).to eq({ "Authorization" => "bearer " })

      GithubApi::GraphQlClient.add_constants("mock_token")

      expect { GithubApi::GraphQlClient::Schema }.not_to raise_error
      expect { GithubApi::GraphQlClient::Client }.not_to raise_error
      expect { GithubApi::GraphQlClient::DeleteIssueQuery }.not_to raise_error
      expect(GithubApi::GraphQlClient::HttpAdapter.headers("")).to eq({ "Authorization" => "bearer mock_token" })
    end
  end
end
