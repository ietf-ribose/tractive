# frozen_string_literal: true

module GithubApi
  class Client
    module Labels
      def list_labels(repo, params = {})
        JSON.parse(
          Http::Client::Request.get(
            "https://api.github.com/repos/#{repo}/labels",
            {
              "Authorization" => "token #{@token}",
              params: params
            }
          )
        )
      end
      alias labels list_labels

      def create_label(repo, params)
        JSON.parse(
          Http::Client::Request.post(
            "https://api.github.com/repos/#{repo}/labels",
            params.to_json,
            {
              "Authorization" => "token #{@token}",
              "Accept" => "application/vnd.github.v3+json"
            }
          )
        )
      end
    end
  end
end
