require "rails_helper"

RSpec.describe DiscordGuildMemberClient do
  include ActiveSupport::Testing::TimeHelpers

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
    expect(request["User-Agent"]).to eq(described_class::USER_AGENT)
    expect(request.path).to eq("/api/v10/guilds/#{guild_id}/members/#{user_id}")
  end

  it "shares a successful lookup through the cache" do
    cache = ActiveSupport::Cache::MemoryStore.new
    response = Net::HTTPOK.new("1.1", "200", "OK")
    request = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(request)
    allow(request).to receive(:use_ssl=)
    allow(request).to receive(:open_timeout=)
    allow(request).to receive(:read_timeout=)
    allow(request).to receive(:request).once.and_return(response)
    client = described_class.new(bot_token: "bot-token", cache:)

    2.times { expect(client.member?(guild_id, user_id)).to be(true) }
  end

  it "suppresses subsequent requests while Discord is rate limited" do
    cache = ActiveSupport::Cache::MemoryStore.new
    response = Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests")
    response.body = '{"retry_after":120}'
    response.instance_variable_set(:@read, true)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).once.and_return(response)
    client = described_class.new(bot_token: "bot-token", cache:)

    expect { client.member?(guild_id, user_id) }.to raise_error(described_class::Error, /429/)
    travel 61.seconds do
      expect { client.member?(guild_id, "34567890123456789#{0}") }
        .to raise_error(described_class::Error, /rate limited/)
    end
  end

  it "uses the Retry-After header when a 429 body is not JSON" do
    cache = ActiveSupport::Cache::MemoryStore.new
    response = Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests")
    response["Retry-After"] = "120"
    response.body = "not-json"
    response.instance_variable_set(:@read, true)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).once.and_return(response)
    client = described_class.new(bot_token: "bot-token", cache:)

    expect { client.member?(guild_id, user_id) }.to raise_error(described_class::Error, /429/)
    travel 61.seconds do
      expect(cache.exist?(described_class::RATE_LIMIT_KEY)).to be(true)
    end
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

  it "uses a recent successful result during a short API outage" do
    cache = ActiveSupport::Cache::MemoryStore.new
    success = Net::HTTPOK.new("1.1", "200", "OK")
    unavailable = Net::HTTPServiceUnavailable.new("1.1", "503", "Unavailable")
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).twice.and_return(success, unavailable)
    client = described_class.new(bot_token: "bot-token", cache:)

    expect(client.member?(guild_id, user_id)).to be(true)
    travel 61.seconds
    expect(client.member?(guild_id, user_id)).to be(true)
    expect(client.member?(guild_id, user_id)).to be(true)
    expect(http).to have_received(:request).twice
  end

  it "uses a recent non-member result during a short API outage" do
    cache = ActiveSupport::Cache::MemoryStore.new
    not_found = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    unavailable = Net::HTTPServiceUnavailable.new("1.1", "503", "Unavailable")
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(not_found, unavailable)
    client = described_class.new(bot_token: "bot-token", cache:)

    expect(client.member?(guild_id, user_id)).to be(false)
    travel 61.seconds
    expect(client.member?(guild_id, user_id)).to be(false)
  end
end
