require "rails_helper"

RSpec.describe "Responsive scenario forms" do
  it "keeps new and edit forms accessible at supported widths" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    editor = create(:person, roles: %w[admin gm])
    user = create(:user, person: editor)
    scenario = create(:scenario, title: "編集するシナリオ")
    scenario.purchase_links.create!(label: "とても長い名前のオンラインストア", url: "https://example.com/item")
    create(:author, name: "見本作者")
    create(:game_system, name: "見本システム")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    sign_in_with_google

    [ new_scenario_path, edit_scenario_path(scenario) ].each do |path|
      [ 320, 768, 1280 ].each do |width|
        page.current_window.resize_to(width, 1000)
        visit path
        expect(page).to have_css("body.bg-ui-background.text-ui-text")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        expect(page).to be_axe_clean
        expect(all('form input:not([type="hidden"]):not([type="checkbox"]):not([type="radio"]), form textarea, form select, form button').select(&:visible?).all? do |control|
          control.rect.height >= 44
        end).to be(true)
        expect(all('form input[type="checkbox"], form input[type="radio"]').select(&:visible?).all? do |control|
          control.find(:xpath, "parent::label").rect.height >= 44
        end).to be(true)
        save_screenshot("scenario-form-#{path == new_scenario_path ? 'new' : 'edit'}-#{width}.png") if ENV["VISUAL_REVIEW"]
      end
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
