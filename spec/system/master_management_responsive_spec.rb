require "rails_helper"

RSpec.describe "Responsive master management screens" do
  it "keeps author, game system and group management accessible at supported widths" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    admin = create(:person, roles: %w[admin gm], display_name: "管理者")
    member = create(:person, display_name: "狭い画面でも折り返して表示できる長い人物名")
    author = create(:author, name: "狭い画面でも折り返して表示できる長い作者名")
    author.aliases.create!(name: "公開される作者の別名", visible: true)
    game_system = create(:game_system, name: "狭い画面でも折り返して表示できる長いゲームシステム名")
    group = create(:group, name: "狭い画面でも折り返して表示できる長いグループ名", people: [ member ])
    user = create(:user, person: admin)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    visit root_path
    click_button "Googleでログイン"
    expect(page).to have_link(admin.display_name, href: person_path(admin))

    paths = [
      authors_path, author_path(author), new_author_path, edit_author_path(author),
      game_systems_path, game_system_path(game_system), new_game_system_path, edit_game_system_path(game_system),
      manage_groups_path, manage_group_path(group), edit_manage_group_path(group)
    ]

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      paths.each do |path|
        visit path
        expect(page).to have_css('main[data-ui-theme="dark"]'), path
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true), path
        expect(page).to be_axe_clean
      end
      save_screenshot("master-management-#{width}.png") if ENV["VISUAL_REVIEW"]
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
