require "rails_helper"

RSpec.describe "Editor navigation" do
  it "moves through every signed-in list, detail and form without a broken Turbo visit" do
    editor = create(:person, roles: %w[admin], display_name: "管理者")
    scenario = create(:scenario, title: "見本シナリオ")
    play_session = create(:play_session, scenario: scenario)
    create(:participation, play_session: play_session, person: editor, role: :gm)
    keeper_system = create(:game_system, name: "探索システム", game_master_label: "KP")
    keeper_scenario = create(:scenario, title: "探索シナリオ", game_systems: [ keeper_system ])
    create(:author, name: "見本作者")
    create(:game_system, name: "見本システム")
    user = create(:user, person: editor)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    visit root_path
    click_button "ログイン"
    save_screenshot("editor-scenarios.png") if ENV["VISUAL_REVIEW"]
    if ENV["CHROME_BINARY"]
      click_button "メニュー"
      expect(page).to have_css('#account-menu:not([hidden])')
      save_screenshot("editor-menu.png") if ENV["VISUAL_REVIEW"]
      click_button "メニュー"
    end

    click_link "新規登録"
    expect(page).to have_css("h1", text: "シナリオの新規登録")
    expect(page).to have_no_content("Content missing")
    expect(page).to have_link("一覧に戻る", count: 1)
    save_screenshot("editor-scenario-new.png") if ENV["VISUAL_REVIEW"]

    visit play_sessions_path
    expect(page).to have_content("全1件")
    save_screenshot("editor-sessions.png") if ENV["VISUAL_REVIEW"]
    click_link "新規登録"
    expect(page).to have_css("h1", text: "セッションの新規登録")
    expect(page).to have_link("一覧に戻る", count: 1)

    visit people_path
    click_link editor.display_name, match: :first
    expect(page).to have_link("編集", count: 1)
    save_screenshot("editor-person.png") if ENV["VISUAL_REVIEW"]

    visit scenario_path(scenario)
    expect(page).to have_link("編集", href: edit_scenario_path(scenario))

    visit play_session_path(play_session)
    expect(page).to have_link("編集", href: edit_play_session_path(play_session))
    click_link "編集"
    expect(page).to have_css("h1", text: "セッションの編集")
    expect(page).to have_button("更新")
    if ENV["CHROME_BINARY"]
      select keeper_scenario.title, from: "シナリオ"
      expect(page).to have_select("役割", with_options: %w[KP サブKP])
      click_button "参加者を足す"
      expect(page).to have_select("役割", with_options: %w[KP サブKP], count: 2)
    end

    visit authors_path
    expect(page).to have_link("新規登録", href: new_author_path)
    save_screenshot("editor-authors.png") if ENV["VISUAL_REVIEW"]
    click_link "新規登録"
    expect(page).to have_css("h1", text: "作者の新規登録")
    expect(page).to have_link("一覧に戻る", count: 1)

    visit game_systems_path
    expect(page).to have_link("新規登録", href: new_game_system_path)
    click_link "新規登録"
    expect(page).to have_css("h1", text: "システムの新規登録")
    expect(page).to have_link("一覧に戻る", count: 1)

    if ENV["VISUAL_REVIEW"]
      page.current_window.resize_to(390, 844)
      visit root_path
      save_screenshot("editor-mobile.png")
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
