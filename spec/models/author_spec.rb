require "rails_helper"

RSpec.describe Author do
  it "requires a name" do
    expect(described_class.new(name: "")).not_to be_valid
  end

  it "rejects a duplicate name" do
    described_class.create!(name: "ディズム")

    expect(described_class.new(name: "ディズム")).not_to be_valid
  end
end
