require "rails_helper"

RSpec.describe "Browsing scenarios" do
  it "goes from the list to a detail page without signing in" do
    create(
      :scenario,
      title: "カタシロ",
      synopsis: "はじめてのソロシナリオに最適。",
      preparation_note: "ネタバレを含む準備情報",
      player_count_min: 1,
      player_count_max: 1,
      duration_min_hours: 2,
      recommendation: 5,
      game_systems: [ create(:game_system, name: "CoC 7版") ],
      authors: [ create(:author, name: "ディズム") ]
    )

    visit root_path
    expect(page).to be_axe_clean if ENV["CHROME_BINARY"].present?
    expect(page).to have_content("シナリオ一覧")
    expect(page).to have_no_content("★")

    click_link "カタシロ"

    expect(page).to have_content("ディズム")
    expect(page).to have_content("CoC 7版")
    expect(page).to have_content("2時間")
    expect(page).to have_no_content("ネタバレを含む準備情報")
  end
end
