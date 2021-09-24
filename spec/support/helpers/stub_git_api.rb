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
  end
end
