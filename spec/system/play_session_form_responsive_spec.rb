require "rails_helper"

RSpec.describe "Responsive play session forms" do
  it "keeps nested schedules and participants accessible at supported widths" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    editor = create(:person, roles: %w[admin gm], display_name: "編集者")
    participant = create(:person, display_name: "参加者")
    user = create(:user, person: editor)
    scenario = create(:scenario, title: "編集するセッションのシナリオ")
    play_session = create(:play_session, scenario:, note: "長いメモ")
    schedule = create(:session_schedule, play_session:, scheduled_on: Date.new(2026, 8, 24))
    create(:recording_link, session_schedule: schedule, url: "https://example.com/recording")
    create(:participation, play_session:, person: participant, role: :player,
      character_name: "長い名前のキャラクター", character_sheet_url: "https://example.com/character")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    visit root_path
    click_button "Googleでログイン"

    [ new_play_session_path, edit_play_session_path(play_session) ].each do |path|
      [ 320, 768, 1280 ].each do |width|
        page.current_window.resize_to(width, 1000)
        visit path
        expect(page).to have_css('main[data-ui-theme="dark"]')
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        expect(page).to be_axe_clean
        expect(all('[data-nested-form-target="anchor"]', visible: :all).length).to be >= 3 if path == edit_play_session_path(play_session)
        save_screenshot("play-session-form-#{path == new_play_session_path ? 'new' : 'edit'}-#{width}.png") if ENV["VISUAL_REVIEW"]
      end
    end

    page.current_window.resize_to(320, 1000)
    visit new_play_session_path
    click_button "日程を足す"
    expect(page).to have_field("開催日", count: 1)
    click_button "録画リンクを足す"
    expect(page).to have_field("録画URL", count: 1)
    click_button "参加者を足す"
    expect(page).to have_select("名前", count: 1)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    expect(page).to be_axe_clean
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
