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
    click_button "Discordでログイン"
    # click_button は遷移の完了を待たない。DOM で待つと認証のリダイレクト途中の
    # 差し替えに当たり、Selenium が stale node で落ちる。URL で着地を待つ。
    expect(page).to have_current_path(root_path, wait: 10)
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
