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

module SystemAuthenticationHelpers
  # ヘッダーに出すのは Discord だけになったため、Google は新規登録ページから開始する。
  def sign_in_with_google
    visit new_registration_path
    click_button "Google でログイン"
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
