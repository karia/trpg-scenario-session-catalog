require "rails_helper"

RSpec.describe Participation do
  it "covers the three roles at the table" do
    expect(described_class.roles.keys).to match_array(%w[gm player sub_gm])
  end

  it "allows a GM to have no character sheet" do
    expect(build(:participation, role: :gm, character_name: nil, character_sheet_url: nil)).to be_valid
  end

  it "records a character sheet for a player" do
    participation = build(:participation, role: :player, character_name: "探索者A",
      character_sheet_url: "https://charasheet.vampire-blood.net/1234")

    expect(participation).to be_valid
  end

  it "rejects a character sheet link that is not an http URL" do
    expect(build(:participation, character_sheet_url: "javascript:alert(1)")).not_to be_valid
  end
end
