require "rails_helper"

RSpec.describe "Sessions" do
  let(:discord_client) { instance_double(DiscordGuildMemberClient, member?: false) }

  before do
    allow(DiscordGuildMemberClient).to receive(:new).and_return(discord_client)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "10000001",
      info: { email: "karia@example.com", name: "カーリア" }
    )
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord",
      uid: "23456789012345678#{9}",
      info: { email: "discord@example.com", name: "Discord User" },
      credentials: { token: "discord-token" }
    )
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:discord] = nil
    OmniAuth.config.test_mode = false
  end

  def sign_in(origin: nil)
    post "/auth/google_oauth2", params: { origin: }.compact
    follow_redirect!
  end
  def sign_in_with_discord(origin: nil)
    post "/auth/discord", params: { origin: }.compact
    follow_redirect!
  end

  describe "signing in" do
    it "refuses to start the flow over GET, so another site cannot trigger it" do
      get "/auth/google_oauth2"

      expect(response).to have_http_status(:not_found)
    end

    it "creates an account that is not linked to a person yet" do
      expect { sign_in }.to change(User, :count).by(1)

      expect(User.sole.person).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it "signs in with Discord" do
      expect { sign_in_with_discord }.to change(User, :count).by(1)

      expect(User.sole).to have_attributes(provider: "discord", uid: "23456789012345678#{9}", person: nil)
      expect(session[:user_id]).to eq(User.sole.id)
    end

    it "automatically links a Discord guild member to a new person" do
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      allow(discord_client).to receive(:member?)
        .with(group.discord_guild_id, "23456789012345678#{9}").and_return(true)
      sign_in_with_discord

      expect(User.sole.person.groups).to contain_exactly(group)
      expect(response).to redirect_to(root_path)
    end

    it "uses a prelinked person on their first Discord sign-in" do
      uid = "23456789012345678#{9}"
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      person = create(:person, discord_uid: uid, groups: [ group ])
      allow(discord_client).to receive(:member?).with(group.discord_guild_id, uid).and_return(true)

      expect { sign_in_with_discord }.not_to change(Person, :count)

      expect(User.sole.person).to eq(person)
      expect(session[:user_id]).to eq(User.sole.id)
    end

    it "removes Discord-managed access on the first request after leaving the guild" do
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      allow(discord_client).to receive(:member?).and_return(true)
      sign_in_with_discord
      membership = User.sole.person.group_memberships.find_by!(group:)

      allow(discord_client).to receive(:member?).and_return(false)
      get play_sessions_path

      expect(GroupMembership.exists?(membership.id)).to be(false)
    end

    it "signs in a linked Discord user when fetching guilds fails" do
      person = create(:person)
      user = create(:user, provider: "discord", uid: "23456789012345678#{9}", person:)
      group = create(:group, discord_guild_id: "12345678901234567#{8}")
      membership = person.group_memberships.create!(group:, discord_managed: true)
      allow(discord_client).to receive(:member?)
        .and_raise(DiscordGuildMemberClient::Error, "Discord API returned 503")

      sign_in_with_discord

      expect(session[:user_id]).to eq(user.id)
      expect(GroupMembership.exists?(membership.id)).to be(true)
      expect(response).to redirect_to(root_path)
    end

    it "signs in an unlinked Discord user when fetching guilds fails" do
      create(:group, discord_guild_id: "12345678901234567#{8}")
      allow(discord_client).to receive(:member?)
        .and_raise(DiscordGuildMemberClient::Error, "Discord API returned 503")

      sign_in_with_discord

      expect(session[:user_id]).to eq(User.sole.id)
      expect(User.sole.person).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it "returns to the URL where sign-in started" do
      sign_in(origin: scenario_path(create(:scenario), view: "cards"))

      expect(response).to redirect_to(%r{/scenarios/\d+\?view=cards\z})
    end

    it "does not redirect to another host" do
      sign_in(origin: "https://example.com/phishing")

      expect(response).to redirect_to(root_path)
    end

    it "signs the same account in again without creating another" do
      sign_in
      delete session_path

      expect { sign_in }.not_to change(User, :count)
    end

    it "sends a provider failure to the failure page rather than raising" do
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

      post "/auth/google_oauth2"
      follow_redirect!

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
      expect(User.count).to eq(0)
    end

    it "replaces the session on sign-in, so a fixed cookie cannot be reused" do
      # test 環境は forgery protection を切っているため、トークンを書かせる間だけ有効にする。
      # 有効なままだと omniauth-rails_csrf_protection が開始リクエストを弾く。
      ActionController::Base.allow_forgery_protection = true
      get root_path
      before = session[:_csrf_token]
      ActionController::Base.allow_forgery_protection = false

      expect(before).to be_present

      sign_in

      expect(session[:_csrf_token]).not_to eq(before)
      expect(session[:user_id]).to eq(User.sole.id)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it "answers 404 for a callback from an unknown provider" do
      get "/auth/bogus/callback"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "signing out" do
    it "clears the session" do
      sign_in

      delete session_path

      expect(response).to redirect_to(root_path)
      get people_path
      expect(response).to have_http_status(:not_found)
    end
  end
end
