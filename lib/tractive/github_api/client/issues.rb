# frozen_string_literal: true

module GithubApi
  class Client
    # Methods for the Issues API
    module Issues
      def create_issue(repo, params)
        JSON.parse(
          Http::Client::Request.post(
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
          Http::Client::Request.get(
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
          Http::Client::Request.get(
            "https://api.github.com/repos/#{repo}/issues/#{number}",
            { "Authorization" => "token #{@token}" }
          )
        )
      end

      def issue_import_status(repo, id)
        JSON.parse(
          Http::Client::Request.get(
            "https://api.github.com/repos/#{repo}/import/issues/#{id}",
            {
              "Authorization" => "token #{@token}",
              "Accept" => "application/vnd.github.golden-comet-preview+json"
            }
          )
        )
      end

      def issue_comments(repo, issue_id)
        JSON.parse(
          Http::Client::Request.get(
            "https://api.github.com/repos/#{repo}/issues/#{issue_id}/comments",
            {
              "Authorization" => "token #{@token}",
              "Accept" => "application/vnd.github.golden-comet-preview+json"
            }
          )
        )
      end

      def update_issue_comment(repo, comment_id, comment_body)
        JSON.parse(
          Http::Client::Request.patch(
            "https://api.github.com/repos/#{repo}/issues/comments/#{comment_id}",
            { body: comment_body }.to_json,
            { "Authorization" => "token #{@token}" }
          )
        )
      end
    end
  end
end
