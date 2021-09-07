# frozen_string_literal: true

module GithubApi
  class Client
    # Methods for the Issues API
    module Issues
      def create_issue(repo, params)
        JSON.parse(
          RestClient.post(
            "https://api.github.com/repos/#{repo}/import/issues",
            params.to_json,
            {
              "Authorization" => "token #{@token}",
              "Content-Type" => "application/json",
              "Accept" => "application/vnd.github.golden-comet-preview+json"
            }
          )
        )
      end

      def list_issues(repo, params)
        JSON.parse(
          RestClient.get(
            "https://api.github.com/repos/#{repo}/issues",
            {
              "Authorization" => "token #{@token}",
              params: params
            }
          )
        )
      end
      alias issues list_issues

      def issue(repo, number)
        JSON.parse(
          RestClient.get(
            "https://api.github.com/repos/#{repo}/issues/#{number}",
            { "Authorization" => "token #{@token}" }
          )
        )
      end

      def issue_import_status(repo, id)
        JSON.parse(
          RestClient.get(
            "https://api.github.com/repos/#{repo}/import/issues/#{id}",
            {
              "Authorization" => "token #{@token}",
              "Accept" => "application/vnd.github.golden-comet-preview+json"
            }
          )
        )
      end
    end
  end
end
