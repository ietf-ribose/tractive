# frozen_string_literal: true

require_relative "client/issues"
require_relative "client/labels"
require_relative "client/milestones"

require_relative "../http/client"

require "graphql/client"
require "graphql/client/http"

# Service to perform github actions
module GithubApi
  class Client
    include GithubApi::Client::Issues
    include GithubApi::Client::Labels
    include GithubApi::Client::Milestones

    DELETE_ISSUE_QUERY = <<~QUERY
      mutation ($input: DeleteIssueInput!) {
        deleteIssue(input: $input) {
          repository {
            name
            url
          }
        }
      }
    QUERY

    HttpAdapter = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
      attr_writer :token

      def headers(_context)
        {
          "Authorization" => "bearer #{@token}"
        }
      end
    end

    def initialize(options = {})
      @token = options[:access_token]
    end

    def self.add_graphql_constants(token)
      HttpAdapter.token = token

      GithubApi::Client.const_set("GraphQlSchema", GraphQL::Client.load_schema(HttpAdapter))
      GithubApi::Client.const_set("GraphQlClient", GraphQL::Client.new(schema: GraphQlSchema, execute: HttpAdapter))
      GithubApi::Client.const_set("DeleteIssueQuery", GraphQlClient.parse(DELETE_ISSUE_QUERY))
    end
  end
end
