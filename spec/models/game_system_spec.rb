require "rails_helper"

RSpec.describe GameSystem do
  it "defines the default game master role labels in one place" do
    expect(described_class::DEFAULT_GAME_MASTER_LABEL).to eq("GM")
    expect(described_class::DEFAULT_ROLE_LABELS).to eq(gm: "GM", sub_gm: "サブGM")
  end

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
