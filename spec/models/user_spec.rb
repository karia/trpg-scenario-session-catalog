require "rails_helper"

RSpec.describe User do
  it "encrypts the Google refresh token and scopes" do
    user = create(:user, google_refresh_token: "refresh-token", google_scopes: "email profile")
    stored = described_class.connection.select_one(
      "SELECT google_refresh_token, google_scopes FROM users WHERE id = #{user.id}"
    )

    expect(stored.values).not_to include("refresh-token", "email profile")
    expect(user.reload).to have_attributes(
      google_refresh_token: "refresh-token", google_scopes: "email profile"
    )
  end

  it "requires a provider and UID" do
    expect(build(:user, provider: "", uid: "")).not_to be_valid
  end

  it "rejects a duplicate UID from the same provider" do
    create(:user, provider: "discord", uid: "1234")

    expect(build(:user, provider: "discord", uid: "1234")).not_to be_valid
    expect(build(:user, provider: "google_oauth2", uid: "1234")).to be_valid
  end

  it "is valid without a person, which is how every account starts" do
    expect(build(:user, person: nil)).to be_valid
  end

  it "lets at most one account from each provider point at a person" do
    person = create(:person)
    create(:user, provider: "google_oauth2", person: person)

    expect(build(:user, provider: "google_oauth2", person: person)).not_to be_valid
    expect(build(:user, provider: "discord", person: person)).to be_valid
  end

  describe ".from_google" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "10000001",
        info: { email: "someone@example.com", name: "Someone" }
      )
    end

    it "creates an account that is not linked to a person yet" do
      user = described_class.from_google(auth)

      expect(user).to be_persisted
      expect(user.person).to be_nil
      expect(user.email).to eq("someone@example.com")
    end

    it "returns the same account on the second sign-in" do
      first = described_class.from_google(auth)

      expect { described_class.from_google(auth) }.not_to change(described_class, :count)
      expect(described_class.from_google(auth)).to eq(first)
    end

    it "follows an address change without losing the link to the person" do
      user = described_class.from_google(auth)
      user.update!(person: create(:person))

      described_class.from_google(auth.merge(info: { email: "moved@example.com" }))

      expect(user.reload.email).to eq("moved@example.com")
      expect(user.person).to be_present
    end

    it "adopts an account inserted by an old application instance" do
      legacy = described_class.insert_all!([ {
        google_uid: auth.uid.to_s,
        email: "old@example.com",
        created_at: Time.current,
        updated_at: Time.current
      } ]).then { |result| described_class.find(result.rows.first.first) }

      expect(legacy.uid).to be_nil

      expect { described_class.from_google(auth) }.not_to change(described_class, :count)
      expect(legacy.reload).to have_attributes(uid: auth.uid.to_s, email: "someone@example.com")
    end
  end

  describe ".link_google" do
    let(:person) { create(:person) }
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: "10000001",
        info: { email: "someone@example.com", name: "Someone" },
        credentials: { refresh_token: "refresh-token", scope: "email profile" }
      )
    end

    it "links the Google account and stores its credentials" do
      user = described_class.link_google(auth, person)

      expect(user).to have_attributes(
        person:, provider: "google_oauth2", uid: "10000001",
        google_refresh_token: "refresh-token", google_scopes: "email profile"
      )
    end

    it "refuses to move another person's Google account" do
      described_class.link_google(auth, create(:person))

      expect { described_class.link_google(auth, person) }.to raise_error(ArgumentError)
    end

    it "requires a refresh token" do
      auth.credentials.delete(:refresh_token)

      expect { described_class.link_google(auth, person) }.to raise_error(ArgumentError)
    end
  end

  describe "#unlink_google!" do
    it "revokes and clears a Google link" do
      user = create(:user, person: create(:person), google_refresh_token: "refresh-token", google_scopes: "email")
      allow(GoogleTokenRevoker).to receive(:revoke)

      user.unlink_google!

      expect(GoogleTokenRevoker).to have_received(:revoke).with("refresh-token")
      expect(user.reload).to have_attributes(person: nil, google_refresh_token: nil, google_scopes: nil)
    end
  end

  it "revokes Google access before the user is destroyed" do
    user = create(:user, google_refresh_token: "refresh-token")
    allow(GoogleTokenRevoker).to receive(:revoke)

    user.destroy!

    expect(GoogleTokenRevoker).to have_received(:revoke).with("refresh-token")
  end

  describe ".from_omniauth" do
    it "creates and finds a Discord account by provider and UID" do
      auth = OmniAuth::AuthHash.new(
        provider: "discord", uid: "20000001", info: { email: "discord@example.com", name: "Discord User" }
      )

      first = described_class.from_omniauth(auth)

      expect(first.provider).to eq("discord")
      expect(first.uid).to eq("20000001")
      expect(first.name).to eq("Discord User")
      expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
    end

    it "links a new Discord account to a prelinked person" do
      uid = "23456789012345678#{9}"
      person = create(:person, discord_uid: uid)
      auth = OmniAuth::AuthHash.new(
        provider: "discord", uid:, info: { email: "discord@example.com", name: "Discord User" }
      )

      user = described_class.from_omniauth(auth)

      expect(user.person).to eq(person)
      expect { user.sync_discord_groups!(client: instance_double(DiscordGuildMemberClient)) }
        .not_to change(Person, :count)
    end

    it "links an existing unlinked Discord account to a concurrently prelinked person" do
      uid = "23456789012345678#{9}"
      person = create(:person, discord_uid: uid)
      user = create(:user, provider: "discord", uid:, person: nil)
      auth = OmniAuth::AuthHash.new(provider: "discord", uid:, info: { name: "Discord User" })

      expect(described_class.from_omniauth(auth)).to eq(user)
      expect(user.reload.person).to eq(person)
    end
  end

  describe "#sync_discord_groups!" do
    let(:user_id) { "23456789012345678#{9}" }
    let(:client) { instance_double(DiscordGuildMemberClient) }

    it "creates a person and a Discord-managed membership for a guild member" do
      user = create(:user, provider: "discord", uid: user_id, person: nil, name: "Discord User")
      matched_guild_id = "12345678901234567#{8}"
      other_guild_id = "98765432109876543#{2}"
      matched = create(:group, discord_guild_id: matched_guild_id)
      other = create(:group, discord_guild_id: other_guild_id)
      allow(client).to receive(:member?).with(matched_guild_id, user_id).and_return(true)
      allow(client).to receive(:member?).with(other_guild_id, user_id).and_return(false)

      user.sync_discord_groups!(client:)

      expect(user.reload.person.display_name).to eq("Discord User")
      expect(user.person.groups).to contain_exactly(matched)
      expect(user.person.groups).not_to include(other)
      expect(user.person.group_memberships.sole).to be_discord_managed
    end

    it "leaves an unmatched account unlinked" do
      user = create(:user, provider: "discord", uid: user_id, person: nil)
      create(:group, discord_guild_id: "12345678901234567#{8}")
      allow(client).to receive(:member?).and_return(false)

      expect { user.sync_discord_groups!(client:) }.not_to change(Person, :count)
      expect(user.reload.person).to be_nil
    end

    it "does not convert an existing manual membership" do
      person = create(:person)
      user = create(:user, provider: "discord", uid: user_id, person:)
      group = create(:group, discord_guild_id: "12345678901234567#{8}", people: [ person ])
      allow(client).to receive(:member?).and_return(true)

      expect { user.sync_discord_groups!(client:) }
        .not_to change(GroupMembership, :count)
      expect(person.group_memberships.find_by(group:)).not_to be_discord_managed
    end

    it "removes a Discord-managed membership after the user leaves the guild" do
      person = create(:person)
      user = create(:user, provider: "discord", uid: user_id, person:)
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      person.group_memberships.create!(group:, discord_managed: true)
      allow(client).to receive(:member?).and_return(false)

      expect { user.sync_discord_groups!(client:) }.to change(GroupMembership, :count).by(-1)
    end

    it "keeps a Discord-managed membership when Discord cannot confirm it" do
      person = create(:person)
      user = create(:user, provider: "discord", uid: user_id, person:)
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      person.group_memberships.create!(group:, discord_managed: true)
      allow(client).to receive(:member?).and_raise(DiscordGuildMemberClient::Error)

      expect { user.sync_discord_groups!(client:) }.not_to change(GroupMembership, :count)
      expect(person.group_memberships.find_by(group:)).to be_discord_managed
    end

    it "enforces one deadline across all configured guilds" do
      stub_const("User::DISCORD_SYNC_DEADLINE", 0.01.seconds)
      user = create(:user, provider: "discord", uid: user_id, person: nil)
      create(:group, discord_guild_id: "12345678901234567#{8}")
      create(:group, discord_guild_id: "98765432109876543#{2}")
      allow(client).to receive(:member?) { sleep 0.02; true }

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      user.sync_discord_groups!(client:)

      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).to be < 0.04
      expect(client).to have_received(:member?).once
      expect(user.reload.person).to be_nil
    end

    it "keeps unchecked Discord-managed memberships after the deadline" do
      stub_const("User::DISCORD_SYNC_DEADLINE", 0.01.seconds)
      person = create(:person)
      user = create(:user, provider: "discord", uid: user_id, person:)
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      person.group_memberships.create!(group:, discord_managed: true)
      allow(client).to receive(:member?) { sleep 0.02; false }

      expect { user.sync_discord_groups!(client:) }.not_to change(GroupMembership, :count)
      expect(person.group_memberships.find_by(group:)).to be_discord_managed
    end
  end
end
