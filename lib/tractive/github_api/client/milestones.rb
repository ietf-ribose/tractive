# frozen_string_literal: true

module GithubApi
  class Client
    # Methods for the Issues API
    module Milestones
      def list_milestones(repo, params)
        JSON.parse(
          RestClient.get(
            "https://api.github.com/repos/#{repo}/milestones?per_page=100",
            {
              "Authorization" => "token #{@token}",
              params: params
            }
          )
        )
      end
      alias milestones list_milestones

      def create_milestone(repo, params)
        JSON.parse(
          RestClient.post(
            "https://api.github.com/repos/#{repo}/milestones",
            params.to_json,
            {
              "Authorization" => "token #{@token}",
              "Content-Type" => "application/json",
              "Accept" => "application/vnd.github.golden-comet-preview+json"
            }
          )
        )
      end
    end
  end
end
