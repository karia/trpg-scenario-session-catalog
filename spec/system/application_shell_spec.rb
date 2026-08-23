require "rails_helper"

RSpec.describe "Application shell" do
  it "fits every layout at supported viewport widths and keeps the shell accessible" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    admin = create(:person, roles: %w[admin])
    user = create(:user, person: admin)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    visit root_path
    click_button "Googleでログイン"

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      {
        application: root_path,
        manage: manage_groups_path,
        error: scenario_path(-1)
      }.each do |layout, path|
        visit path
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true),
          "#{layout} layout overflowed at #{width}px"
        expect(page).to be_axe_clean.excluding("#main-content") unless layout == :error
        expect(page).to be_axe_clean if layout == :error
        save_screenshot("#{layout}-shell-#{width}.png") if ENV["VISUAL_REVIEW"]
      end
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
