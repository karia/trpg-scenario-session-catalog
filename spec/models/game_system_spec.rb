require "rails_helper"

RSpec.describe GameSystem do
  it "requires a name" do
    expect(described_class.new(name: "")).not_to be_valid
  end

  it "rejects a duplicate name" do
    described_class.create!(name: "エモクロアTRPG")

    expect(described_class.new(name: "エモクロアTRPG")).not_to be_valid
  end

  it "orders by name" do
    described_class.create!(name: "エモクロアTRPG")
    described_class.create!(name: "CoC 6版")

    expect(described_class.all.map(&:name)).to eq([ "CoC 6版", "エモクロアTRPG" ])
  end
end
