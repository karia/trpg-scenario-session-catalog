require "rails_helper"

RSpec.describe DiscordGuildsClient do
  it "returns guild IDs from Discord" do
    guild_id = "12345678901234567#{8}"
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.body = [ { id: guild_id, name: "卓" } ].to_json
    response.instance_variable_set(:@read, true)
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect(described_class.new.guild_ids("access-token")).to eq([ guild_id ])
  end

  it "raises a controlled error when Discord rejects the token" do
    response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect { described_class.new.guild_ids("bad-token") }
      .to raise_error(DiscordGuildsClient::Error, "Discord API returned 401")
  end
end
