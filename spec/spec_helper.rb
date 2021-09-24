# frozen_string_literal: true

require "tractive"
require "webmock/rspec"

require_relative "support/helpers/stub_git_api"
require_relative "support/helpers/common_functions"
require_relative "support/helpers/ticket_compose"

WebMock.disable_net_connect!(allow_localhost: true)
CONFIG = YAML.load_file("spec/files/test.config.yaml")

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:suite) do
    Tractive::Utilities.setup_logger(verbose: false)
    Tractive::Utilities.setup_db!(CONFIG["trac"]["database"])
  end

  config.include Helpers::StubGitApi
  config.include Helpers::CommonFunctions
  config.include Helpers::TicketCompose

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
