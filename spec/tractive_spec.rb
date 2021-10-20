# frozen_string_literal: true

RSpec.describe Tractive do
  it "has a version number" do
    expect(Tractive::VERSION).not_to be nil
  end

  it "has working info command" do
    expect(Tractive::Info.new.send(:result_hash)).to eq(db_result_hash)
  end

  def db_result_hash
    result = CONFIG.slice("users", "milestones", "labels")
    result["users"].each do |user, user_attr|
      result["users"][user] = { "email" => user_attr["email"], "name" => nil, "username" => nil }
    end

    result
  end
end
