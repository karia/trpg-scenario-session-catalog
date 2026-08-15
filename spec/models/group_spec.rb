require "rails_helper"

RSpec.describe Group do
  it "accepts one unique Discord guild ID" do
    guild_id = "12345678901234567#{8}"
    create(:group, discord_guild_id: guild_id)

    expect(build(:group, discord_guild_id: guild_id)).not_to be_valid
    expect(build(:group, discord_guild_id: "not-an-id")).not_to be_valid
    expect(build(:group, discord_guild_id: "")).to be_valid
  end
end
