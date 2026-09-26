require "rails_helper"

RSpec.describe "Responsive scenario lists" do
  it "applies the conditions chosen in the filter tray at once and keeps the focus in place" do
    skip "Chrome is required for Turbo interaction checks" unless ENV["CHROME_BINARY"].present?

    author = create(:author, name: "追加する作者")
    system = create(:game_system, name: "探すシステム")
    create(:scenario, title: "作者で探せるシナリオ", authors: [ author ], game_systems: [ system ], player_count_min: 2)
    create(:scenario, title: "条件に合わないシナリオ", player_count_min: 1, player_count_max: 1)

    visit root_path
    click_button "絞り込み"
    within("dialog[open]") do
      choose "2人"
      check "探すシステム"
      fill_in "作者を追加", with: author.name
      click_button "適用する"
    end

    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_no_text("条件に合わないシナリオ")
    expect(page).to have_button("絞り込み（3）")
    expect(page).to have_css("#filter-button:focus")

    find(%(a[aria-label="#{author.name}を解除"])).click

    expect(page).to have_no_css(%(a[aria-label="#{author.name}を解除"]))
    expect(page).to have_button("絞り込み（2）")
    expect(page).to have_css("#filter-button:focus")

    click_button "絞り込み（2）"
    expect(page).to have_css("dialog[open]")
    page.send_keys(:escape)
    expect(page).to have_no_css("dialog[open]")

    find_field("並び順").send_keys(:down)

    expect(page).to have_current_path(/order=\w+/)
    expect(page).to have_css("#order:focus")
  end

  it "reflows both list modes and ordering without horizontal controls" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    author = create(:author, name: "長い名前の作者")
    scenario = create(:scenario, title: "狭い画面でも読める長いシナリオ名", player_count_min: 2,
      duration_min_hours: 3, game_systems: [ create(:game_system, name: "長い名前のゲームシステム") ], authors: [ author ])
    admin = create(:person, roles: %w[admin])
    user = create(:user, person: admin)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      visit root_path(author_ids: [ author.id ])
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)

      if width < 1024
        expect(page).to have_no_css("table", visible: :visible)
        expect(page).to have_css("ul.lg\\:hidden li", text: scenario.title, visible: :visible)
      else
        expect(page).to have_css("table", visible: :visible)
      end
      remove_author = find(%(a[aria-label="#{author.name}を解除"]), visible: :visible)
      expect(remove_author.rect.width).to be >= 44
      expect(remove_author.rect.height).to be >= 44
      expect(page).to be_axe_clean
      expect(page).to have_no_field("1人", visible: :visible)
      click_button "絞り込み（1）"
      expect(page).to have_field("1人", visible: :visible)
      expect(page).to be_axe_clean
      save_screenshot("scenario-filter-#{width}.png") if ENV["VISUAL_REVIEW"]
      page.send_keys(:escape)
      save_screenshot("scenario-table-#{width}.png") if ENV["VISUAL_REVIEW"]

      visit root_path(view: "gallery", author_ids: [ author.id ])
      expect(page).to have_css(".aspect-3\\/4", visible: :visible)
      expect(find(".aspect-3\\/4").ancestor("article")).to have_text(author.name)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean
      save_screenshot("scenario-gallery-#{width}.png") if ENV["VISUAL_REVIEW"]
    end

    scenario_without_author = create(:scenario, title: "作者未設定のシナリオ")
    visit root_path(view: "gallery")
    expect(find("article", text: scenario_without_author.title)).to have_text("作者未設定")

    sign_in_with_google
    [ 320, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      visit root_path
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to have_link("編集", visible: :visible)
      expect(page).to have_button("削除", visible: :visible)
      expect(page).to be_axe_clean
      save_screenshot("scenario-actions-#{width}.png") if ENV["VISUAL_REVIEW"]
    end

    expect(find_field("並び順").rect.width).to be <= 320

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      visit scenario_order_index_path
      expect(page).to have_link(scenario.title)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean
      save_screenshot("scenario-order-#{width}.png") if ENV["VISUAL_REVIEW"]
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
