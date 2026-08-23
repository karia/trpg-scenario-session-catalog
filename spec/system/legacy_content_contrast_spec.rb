require "rails_helper"

RSpec.describe "Legacy content contrast" do
  it "keeps every not-yet-migrated screen accessible on its legacy surface" do
    skip "Chrome is required for axe checks" unless ENV["CHROME_BINARY"].present?

    admin = create(:person, roles: %w[admin gm])
    current_user = create(:user, person: admin)
    person = create(:person)
    scenario = create(:scenario)
    play_session = create(:play_session, scenario:)
    user = create(:user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: current_user.google_uid, info: { email: current_user.email }
    )

    visit root_path
    click_button "Googleでログイン"
    expect(page).to have_link(admin.display_name, href: person_path(admin))

    legacy_paths = [
      new_scenario_path, edit_scenario_path(scenario),
      new_play_session_path, edit_play_session_path(play_session)
    ]

    legacy_paths.each do |path|
      visit path
      expect(page).to have_css('main[data-ui-theme="legacy"].bg-paper.text-ink'), path
      expect(page).to be_axe_clean.checking_only("color-contrast")
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
