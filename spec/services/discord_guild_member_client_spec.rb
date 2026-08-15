require "rails_helper"

RSpec.describe DiscordGuildMemberClient do
  let(:guild_id) { "12345678901234567#{8}" }
  let(:user_id) { "23456789012345678#{9}" }

  it "reports a guild member using the bot token" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    request = nil
    allow_any_instance_of(Net::HTTP).to receive(:request) do |_http, value|
      request = value
      response
    end

    expect(described_class.new(bot_token: "bot-token").member?(guild_id, user_id)).to be(true)
    expect(request["Authorization"]).to eq("Bot bot-token")
    expect(request.path).to eq("/api/v10/guilds/#{guild_id}/members/#{user_id}")
  end

  it "reports a non-member from Discord's 404 response" do
    response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect(described_class.new(bot_token: "bot-token").member?(guild_id, user_id)).to be(false)
  end

  it "raises a controlled error for an unavailable API" do
    response = Net::HTTPServiceUnavailable.new("1.1", "503", "Unavailable")
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect { described_class.new(bot_token: "bot-token").member?(guild_id, user_id) }
      .to raise_error(DiscordGuildMemberClient::Error, "Discord API returned 503")
  end
end
