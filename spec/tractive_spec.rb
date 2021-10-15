# frozen_string_literal: true

RSpec.describe Tractive do
  it "has a version number" do
    expect(Tractive::VERSION).not_to be nil
  end

  it "has working info command" do
    expect(Tractive::Info.new.send(:result_hash)).to eq(db_result_hash)
  end

  def db_result_hash
    result_hash = CONFIG.slice("users", "milestones", "labels")
    result_hash["users"] = result_hash["users"].map do |user|
      {
        "email" => user["username"] || "",
        "name" => nil,
        "username" => nil
      }
    end
    result_hash
  end
end
