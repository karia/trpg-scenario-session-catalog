require "rails_helper"

RSpec.describe "A member's own pages" do
  it "edits a profile, favours a scenario and opens a spoiler" do
    person = create(:person, display_name: "本人")
    person.person_aliases.create!(name: "古い別名", context: "とあるサーバ")
    scenario = create(:scenario, title: "見本シナリオ", preparation_note: "ネタバレを含む準備情報")
    user = create(:user, person: person)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )
    visit root_path
    click_button "Google でログイン"

    visit edit_person_path(person)
    fill_in "person[x_account]", with: "karia"
    # 既存の別名の行が出ていること自体も確かめる。
    expect(page).to have_field(with: "古い別名")
    fill_in "person[aliases_attributes][0][name]", with: "べつの名前"
    click_button "保存"

    expect(page).to have_content("@karia")
    expect(page).to have_content("べつの名前")
    expect(page).to have_no_content("古い別名")

    visit scenario_path(scenario)
    expect(page).to have_no_content("ネタバレを含む準備情報")

    click_button "プレーヤー向け事前情報を見る"
    expect(page).to have_content("ネタバレを含む準備情報")

    click_button "プレーヤー向け事前情報を閉じる"
    expect(page).to have_no_content("ネタバレを含む準備情報")

    visit scenario_path(scenario)
    click_button "お気に入りに入れる"

    visit person_path(person)
    expect(page).to have_content("見本シナリオ")
  end
end
