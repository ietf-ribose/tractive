# frozen_string_literal: true

require_relative "client/issues"
require_relative "client/labels"
require_relative "client/milestones"

require_relative "../http/client"

# Service to perform github actions
module GithubApi
  class Client
    include GithubApi::Client::Issues
    include GithubApi::Client::Labels
    include GithubApi::Client::Milestones

    def initialize(options = {})
      @token = options[:access_token]
    end
  end
end
