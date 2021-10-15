# frozen_string_literal: true

require "tractive"
require "webmock/rspec"

require_relative "support/helpers/stub_git_api"
require_relative "support/helpers/common_functions"
require_relative "support/helpers/ticket_compose"

WebMock.disable_net_connect!(allow_localhost: true)
CONFIG = YAML.load_file("spec/files/test.config.yaml")
CONFIG["users"] = CONFIG["users"].map { |user| [user["email"], user["username"]] }.to_h

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:suite) do
    Tractive::Utilities.setup_logger(verbose: false)
    Tractive::Utilities.setup_db!(CONFIG["trac"]["database"])
  end

  config.before(:all, &:silence_output)
  config.after(:all,  &:enable_output)

  config.include Helpers::StubGitApi
  config.include Helpers::CommonFunctions
  config.include Helpers::TicketCompose

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

public

# Redirects stderr and stout to /dev/null.txt
def silence_output
  # Store the original stderr and stdout in order to restore them later
  @original_stderr = $stderr
  @original_stdout = $stdout

  # Redirect stderr and stdout
  $stderr = File.new(File.join(File.dirname(__FILE__), "dev", "null.txt"), "w+")
  $stdout = File.new(File.join(File.dirname(__FILE__), "dev", "null.txt"), "w+")
end

# Replace stderr and stdout so anything else is output correctly
def enable_output
  $stderr = @original_stderr
  $stdout = @original_stdout
  @original_stderr = nil
  @original_stdout = nil
end
