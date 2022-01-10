# frozen_string_literal: true

module GithubApi
  class GraphQlClient
    # Methods for the Issues API
    module Issues
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

      def delete_issue(issue_id)
        variables = {
          "input" => {
            "issueId" => issue_id
          }
        }

        Client.query(DeleteIssueQuery, variables: variables)
      end
    end
  end
end
