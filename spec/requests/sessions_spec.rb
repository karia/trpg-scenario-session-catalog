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

  def sign_in
    post "/auth/google_oauth2"
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

    it "signs the same account in again without creating another" do
      sign_in
      delete session_path

      expect { sign_in }.not_to change(User, :count)
    end

    it "reports a failure from the provider instead of raising" do
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

      post "/auth/google_oauth2"
      follow_redirect!
      follow_redirect!

      expect(response).to redirect_to(root_path).or have_http_status(:ok)
      expect(User.count).to eq(0)
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
