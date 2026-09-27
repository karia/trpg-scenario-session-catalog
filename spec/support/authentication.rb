module AuthenticationHelpers
  def sign_in_as(person_or_user)
    user = if person_or_user.is_a?(Person)
      create(:user, provider: "discord", uid: format("9%017d", person_or_user.id), person: person_or_user)
    else
      person_or_user
    end

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[user.provider.to_sym] = OmniAuth::AuthHash.new(
      provider: user.provider, uid: user.uid, info: { email: user.email, name: user.name }
    )
    post "/auth/#{user.provider}"
    follow_redirect!
    user
  end
end

module SystemAuthenticationHelpers
  def sign_in_with_discord
    visit root_path
    page.execute_script("window.signInPending = true")
    click_button "Discordでログイン"
    # 着地先も root_path なので URL では待てない。遷移中の DOM に触れると Selenium が落ちるため、元のページの目印が消えるまで待つ。
    page.document.synchronize(10) do
      pending = begin
        page.evaluate_script("window.signInPending === true")
      rescue Selenium::WebDriver::Error::WebDriverError
        true
      end
      raise Capybara::ExpectationNotMet if pending
    end
    expect(page).to have_content("ログインしました")
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include SystemAuthenticationHelpers, type: :system
  config.after(type: :request) do
    User::PROVIDERS.each_key { |provider| OmniAuth.config.mock_auth[provider.to_sym] = nil }
    OmniAuth.config.test_mode = false
  end
end
