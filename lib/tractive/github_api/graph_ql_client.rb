# frozen_string_literal: true

require_relative "graph_ql_client/issues"

require "graphql/client"
require "graphql/client/http"

# Service to perform github actions
module GithubApi
  class GraphQlClient
    include GithubApi::GraphQlClient::Issues

    HttpAdapter = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
      attr_writer :token

      def headers(_context)
        {
          "Authorization" => "bearer #{@token}"
        }
      end
    end

    def self.add_constants(token)
      HttpAdapter.token = token

      GithubApi::GraphQlClient.const_set("Schema", GraphQL::Client.load_schema(HttpAdapter))
      GithubApi::GraphQlClient.const_set("Client", GraphQL::Client.new(schema: Schema, execute: HttpAdapter))
      GithubApi::GraphQlClient.const_set("DeleteIssueQuery", Client.parse(DELETE_ISSUE_QUERY))
    rescue KeyError
      raise ::StandardError, "Github access token is incorrect or does not have sufficent permissions to access the Github API"
    end
  end
end
