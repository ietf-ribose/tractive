# frozen_string_literal: true

RSpec.describe Tractive::Main do
  it "should Exit if config file is not present" do
    expect { Tractive::Main.new(config: "invalid-file") }.to raise_error(SystemExit)
  end

  it "should not Exit if config file is present" do
    stub_graphql_schema_request

    expect { Tractive::Main.new(options_for_main) }.not_to raise_error
  end

  it "should Exit if filter params are missing" do
    expect { Tractive::Main.new(options_for_main(filter: true)) }.to raise_error(SystemExit)
  end

  it "should not Exit if all filter params are present" do
    stub_graphql_schema_request

    expect do
      Tractive::Main.new(
        options_for_main(
          filter: true,
          columnname: "priority",
          operator: "=",
          columnvalue: "medium"
        )
      )
    end.not_to raise_error
  end

  def options_for_main(options = {})
    options.merge(
      config: "spec/files/test.config.yaml"
    )
  end
end
