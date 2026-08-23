require "rails_helper"

RSpec.describe "Browsing scenarios" do
  it "keeps the scenario detail accessible at supported viewport widths" do
    scenario = create(
      :scenario,
      title: "カタシロ",
      synopsis: "はじめてのソロシナリオに最適。",
      preparation_note: "ネタバレを含む準備情報",
      player_count_min: 1,
      player_count_max: 1,
      duration_min_hours: 2,
      recommendation: 5,
      recommendation_note: "GMからのおすすめ情報",
      character_restriction: "新規キャラクターのみ",
      game_systems: [ create(:game_system, name: "CoC 7版") ],
      authors: [ create(:author, name: "ディズム") ]
    )

    scenario.purchase_links.create!(label: "BOOTH", url: "https://example.com/booth")
    scenario.stream_links.create!(label: "長い名前のおすすめ配信", url: "https://example.com/stream")

    visit root_path
    expect(page).to have_content("シナリオ一覧")
    expect(page).to have_no_content("★")

    click_link "カタシロ", match: :first

    expect(page).to have_content("ディズム")
    expect(page).to have_content("CoC 7版")
    expect(page).to have_content("2時間")
    expect(page).to have_no_content("ネタバレを含む準備情報")

    if ENV["CHROME_BINARY"].present?
      [ 320, 768, 1280 ].each do |width|
        page.current_window.resize_to(width, 900)
        visit scenario_path(scenario)
        expect(page).to have_css('main[data-ui-theme="dark"]')
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        expect(page).to be_axe_clean
        if width == 320
          disclosure = find_button("おすすめ配信を開く")
          expect(disclosure.rect.width).to be >= 44
          expect(disclosure.rect.height).to be >= 44
          disclosure.click
          expect(page).to have_link("長い名前のおすすめ配信", visible: :visible)
          expect(page).to be_axe_clean
        end
        save_screenshot("scenario-detail-#{width}.png") if ENV["VISUAL_REVIEW"]
      end

      member = create(:person)
      user = create(:user, person: member)
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
      )
      visit root_path
      click_button "Googleでログイン"
      page.current_window.resize_to(320, 900)
      visit scenario_path(scenario)
      expect(page).to have_content("GMからのおすすめ情報")
      expect(page).to have_content("新規キャラクターのみ")
      expect(page).to have_button("プレーヤー向け事前情報を見る")
      expect(page).to be_axe_clean
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
