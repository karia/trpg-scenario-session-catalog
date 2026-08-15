module AuthenticationHelpers
  def sign_in_as(person_or_user)
    user = person_or_user.is_a?(Person) ? create(:user, person: person_or_user) : person_or_user

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[user.provider.to_sym] = OmniAuth::AuthHash.new(
      provider: user.provider, uid: user.uid, info: { email: user.email, name: user.name }
    )
    post "/auth/#{user.provider}"
    follow_redirect!
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.after(type: :request) do
    User::PROVIDERS.each_key { |provider| OmniAuth.config.mock_auth[provider.to_sym] = nil }
    OmniAuth.config.test_mode = false
  end
end
