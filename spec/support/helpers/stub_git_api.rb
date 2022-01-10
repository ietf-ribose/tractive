# frozen_string_literal: true

module Helpers
  module StubGitApi
    def stub_issues_request
      stub_request(:get, %r{https://api.github.com/repos/test/repo/issues\?*})
        .to_return(status: 200, body: "[]", headers: {})
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
        .with(
          body: "{\"query\":\"query IntrospectionQuery {\\n  __schema {\\n    queryType {\\n      name\\n    }\\n    mutationType {\\n      name\\n    }\\n    subscriptionType {\\n      name\\n    }\\n    types {\\n      ...FullType\\n    }\\n    directives {\\n      name\\n      description\\n      locations\\n      args {\\n        ...InputValue\\n      }\\n    }\\n  }\\n}\\n\\nfragment FullType on __Type {\\n  kind\\n  name\\n  description\\n  fields(includeDeprecated: true) {\\n    name\\n    description\\n    args {\\n      ...InputValue\\n    }\\n    type {\\n      ...TypeRef\\n    }\\n    isDeprecated\\n    deprecationReason\\n  }\\n  inputFields {\\n    ...InputValue\\n  }\\n  interfaces {\\n    ...TypeRef\\n  }\\n  enumValues(includeDeprecated: true) {\\n    name\\n    description\\n    isDeprecated\\n    deprecationReason\\n  }\\n  possibleTypes {\\n    ...TypeRef\\n  }\\n}\\n\\nfragment InputValue on __InputValue {\\n  name\\n  description\\n  type {\\n    ...TypeRef\\n  }\\n  defaultValue\\n}\\n\\nfragment TypeRef on __Type {\\n  kind\\n  name\\n  ofType {\\n    kind\\n    name\\n    ofType {\\n      kind\\n      name\\n      ofType {\\n        kind\\n        name\\n        ofType {\\n          kind\\n          name\\n          ofType {\\n            kind\\n            name\\n            ofType {\\n              kind\\n              name\\n              ofType {\\n                kind\\n                name\\n              }\\n            }\\n          }\\n        }\\n      }\\n    }\\n  }\\n}\",\"operationName\":\"IntrospectionQuery\"}"
        ).to_return(status: 200, body: File.read("spec/files/github_graphql_schema.json"), headers: {})
    end
  end
end
