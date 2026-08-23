require "rails_helper"

RSpec.describe "Responsive people and registration screens" do
  it "keeps registration and every person screen accessible at supported widths" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      visit new_registration_path
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean
    end

    admin = create(:person, roles: %w[admin gm], display_name: "管理者の長い表示名")
    person = create(:person, display_name: "長い表示名でもカードからはみ出さないメンバー")
    person.person_aliases.create!(name: "公開する別名", context: "長い名前のコミュニティ", visible: true)
    create(:group, name: "長い名前の所属グループ")
    user = create(:user, person: admin)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    visit root_path
    click_button "Googleでログイン"

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      [ people_path, person_path(person), new_person_path, edit_person_path(person) ].each do |path|
        visit path
        expect(page).to have_css("body.bg-ui-background.text-ui-text")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        expect(page).to be_axe_clean
      end
      save_screenshot("people-#{width}.png") if ENV["VISUAL_REVIEW"]
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
