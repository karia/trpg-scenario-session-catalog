require "rails_helper"

RSpec.describe "Sessions" do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "10000001",
      info: { email: "karia@example.com", name: "カーリア" }
    )
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  def sign_in(origin: nil)
    post "/auth/google_oauth2", params: { origin: }.compact
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
      get manage_scenarios_path
      expect(response).to have_http_status(:not_found)
    end
  end
end
