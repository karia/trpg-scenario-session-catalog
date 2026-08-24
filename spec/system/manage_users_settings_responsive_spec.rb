require "rails_helper"

RSpec.describe "Responsive user and site-setting screens" do
  it "keeps every migrated management screen accessible at supported widths" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    admin = create(:person, roles: %w[admin], display_name: "管理者")
    current_user = create(:user, person: admin)
    user = create(:user, person: create(:person, display_name: "長い名前の紐づけ先メンバー"), email: "long-account-address@example.com")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: current_user.google_uid, info: { email: current_user.email }
    )
    sign_in_with_google

    paths = [ manage_users_path, manage_user_path(user), edit_manage_user_path(user), manage_site_setting_path, edit_manage_site_setting_path ]
    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      paths.each do |path|
        visit path
        expect(page).to have_css("body.bg-ui-background.text-ui-text")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        expect(page).to be_axe_clean
      end
      save_screenshot("manage-users-settings-#{width}.png") if ENV["VISUAL_REVIEW"]
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
