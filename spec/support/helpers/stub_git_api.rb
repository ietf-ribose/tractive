# frozen_string_literal: true

module Helpers
  module StubGitApi
    def stub_issues_request
      stub_request(:get, %r{https://api.github.com/repos/test/repo/issues\?*})
        .to_return(status: 200, body: "[]", headers: {})
    end

    def stub_issues_request_for_delete_mocked_issues
      body = <<~BODY
        [{
          "id": 1,
          "node_id": "MDU6SXNzdWUx",
          "url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
          "number": 1,
          "title": "Placeholder issue 1 created to align Github issue and trac ticket numbers during migration."
        }]
      BODY
      stub_request(:get, "https://api.github.com/repos/test/repo/issues?filter=all&page=1&state=closed")
        .to_return(status: 200, body: body, headers: {})

      stub_request(:get, "https://api.github.com/repos/test/repo/issues?direction=desc&filter=all&sort=created&state=all")
        .to_return(status: 200, body: "[]", headers: {})

      stub_request(:get, "https://api.github.com/repos/test/repo/issues?filter=all&page=2&state=closed")
        .to_return(status: 200, body: "[]", headers: {})
    end

    def stub_delete_issue
      stub_request(:post, "https://api.github.com/graphql")
        .with(
          body: "{\"query\":\"query IntrospectionQuery {\\n  __schema {\\n    queryType {\\n      name\\n    }\\n    mutationType {\\n      name\\n    }\\n    subscriptionType {\\n      name\\n    }\\n    types {\\n      ...FullType\\n    }\\n    directives {\\n      name\\n      description\\n      locations\\n      args {\\n        ...InputValue\\n      }\\n    }\\n  }\\n}\\n\\nfragment FullType on __Type {\\n  kind\\n  name\\n  description\\n  fields(includeDeprecated: true) {\\n    name\\n    description\\n    args {\\n      ...InputValue\\n    }\\n    type {\\n      ...TypeRef\\n    }\\n    isDeprecated\\n    deprecationReason\\n  }\\n  inputFields {\\n    ...InputValue\\n  }\\n  interfaces {\\n    ...TypeRef\\n  }\\n  enumValues(includeDeprecated: true) {\\n    name\\n    description\\n    isDeprecated\\n    deprecationReason\\n  }\\n  possibleTypes {\\n    ...TypeRef\\n  }\\n}\\n\\nfragment InputValue on __InputValue {\\n  name\\n  description\\n  type {\\n    ...TypeRef\\n  }\\n  defaultValue\\n}\\n\\nfragment TypeRef on __Type {\\n  kind\\n  name\\n  ofType {\\n    kind\\n    name\\n    ofType {\\n      kind\\n      name\\n      ofType {\\n        kind\\n        name\\n        ofType {\\n          kind\\n          name\\n          ofType {\\n            kind\\n            name\\n            ofType {\\n              kind\\n              name\\n              ofType {\\n                kind\\n                name\\n              }\\n            }\\n          }\\n        }\\n      }\\n    }\\n  }\\n}\",\"operationName\":\"IntrospectionQuery\"}",
          headers: {
            "Accept" => "application/json",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "bearer mock_token",
            "Content-Type" => "application/json",
            "User-Agent" => "Ruby"
          }
        ).to_return(status: 200, body: "[]", headers: {})
    end

    def stub_delete_issue_and_return_errors
      body = <<~BODY
        {
          "data": {
            "deleteIssue": ""
          },
          "errors": [{
            "type": "NOT_FOUND",
            "path": ["deleteIssue"],
            "locations": [{"line": 2, "column": 3}],
            "message": "Could not resolve to a node with the global id of 'abc'"
          }]
        }
      BODY

      stub_request(:post, "https://api.github.com/graphql")
        .with(
          body: "{\"query\":\"mutation GithubApi__GraphQlClient__DeleteIssueQuery($input: DeleteIssueInput!) {\\n  deleteIssue(input: $input) {\\n    repository {\\n      name\\n      url\\n    }\\n  }\\n}\",\"variables\":{\"input\":{\"issueId\":\"MDU6SXNzdWUx\"}},\"operationName\":\"GithubApi__GraphQlClient__DeleteIssueQuery\"}",
          headers: {
            "Accept" => "application/json",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "bearer mock_token",
            "Content-Type" => "application/json",
            "User-Agent" => "Ruby"
          }
        ).to_return(status: 200, body: body, headers: {})
    end

    def stub_milestone_map_request
      stub_request(:get, %r{https://api.github.com/repos/test/repo/milestones\?*})
        .to_return(status: 200,
                   body: "[{ \"title\": \"milestone4\", \"number\": 4 }, { \"title\": \"milestone3\", \"number\": 3 },{ \"title\": \"milestone2\", \"number\": 2 },{ \"title\": \"milestone1\", \"number\": 1 } ]",
                   headers: {})
    end

    def stub_milestone_request
      stub_request(:post, "https://api.github.com/repos/test/repo/milestones")
        .to_return(status: 200,
                   body: "[]")
    end

    def stub_get_labels_request
      stub_request(:get, "https://api.github.com/repos/test/repo/labels?page=1&per_page=100")
        .to_return(
          status: 200,
          body: [
            { "name" => "priority_medium" },
            { "name" => "priority_major" },
            { "name" => "priority_minor" }
          ].to_json
        )

      stub_request(:get, "https://api.github.com/repos/test/repo/labels?page=2&per_page=100")
        .to_return(
          status: 200,
          body: [].to_json
        )
    end

    def stub_create_labels_request
      stub_request(:post, "https://api.github.com/repos/test/repo/labels")
        .to_return(status: 200, body: "[]")
    end

    def stub_graphql_schema_request
      stub_request(:post, "https://api.github.com/graphql")
        .to_return(status: 200, body: File.read("spec/files/github_graphql_schema.json"), headers: {})
    end
  end
end
