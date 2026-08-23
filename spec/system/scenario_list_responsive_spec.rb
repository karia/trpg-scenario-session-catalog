require "rails_helper"

RSpec.describe "Responsive scenario lists" do
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
        expect(page).to have_css("dl", visible: :visible)
      else
        expect(page).to have_css("table", visible: :visible)
      end
      expect(page).to have_css("summary", text: "絞り込み", visible: :visible)
      expect(page).to have_no_button("1人", visible: :visible)
      find("summary", text: "絞り込み").click
      expect(page).to have_button("1人", visible: :visible)
      remove_author = find(%(a[aria-label="#{author.name}を解除"]), visible: :visible)
      expect(remove_author.rect.width).to be >= 44
      expect(remove_author.rect.height).to be >= 44
      expect(page).to be_axe_clean
      save_screenshot("scenario-table-#{width}.png") if ENV["VISUAL_REVIEW"]

      visit root_path(view: "gallery", author_ids: [ author.id ])
      expect(page).to have_css(".aspect-3\\/4", visible: :visible)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean
      save_screenshot("scenario-gallery-#{width}.png") if ENV["VISUAL_REVIEW"]
    end

    visit root_path
    click_button "Googleでログイン"
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
