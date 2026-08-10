module AuthenticationHelpers
  def sign_in_as(person_or_user)
    user = person_or_user.is_a?(Person) ? create(:user, person: person_or_user) : person_or_user

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )
    post "/auth/google_oauth2"
    follow_redirect!
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.after(type: :request) do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
