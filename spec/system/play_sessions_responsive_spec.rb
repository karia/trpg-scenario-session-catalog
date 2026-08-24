require "rails_helper"

RSpec.describe "Responsive play session screens" do
  it "reflows the list and detail at supported viewport widths" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    editor = create(:person, roles: %w[gm], display_name: "進行役の長い表示名")
    player = create(:person, display_name: "参加者の長い表示名")
    scenario = create(:scenario, title: "狭い画面でも読める長いシナリオ名")
    play_session = create(:play_session, scenario:, note: "セッションについての長いメモ")
    schedule = create(:session_schedule, play_session:, scheduled_on: Date.new(2026, 8, 24))
    create(:recording_link, session_schedule: schedule, url: "https://example.com/recordings/a-very-long-address")
    create(:participation, play_session:, person: editor, role: :gm)
    create(:participation, play_session:, person: player, role: :player,
      character_name: "長い名前のキャラクター", character_sheet_url: "https://example.com/characters/a-very-long-address")
    user = create(:user, person: editor)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    sign_in_with_google

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      { list: play_sessions_path, detail: play_session_path(play_session) }.each do |screen, path|
        visit path
        expect(page).to have_css("body.bg-ui-background.text-ui-text")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        expect(page).to be_axe_clean
        save_screenshot("play-session-#{screen}-#{width}.png") if ENV["VISUAL_REVIEW"]
      end
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
