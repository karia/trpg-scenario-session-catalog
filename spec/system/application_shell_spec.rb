require "rails_helper"

RSpec.describe "Application shell" do
  it "fits every layout at supported viewport widths and keeps the shell accessible" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    admin = create(:person, roles: %w[admin])
    user = create(:user, person: admin)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    sign_in_with_google

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      {
        application: root_path,
        manage: manage_groups_path,
        error: scenario_path(-1)
      }.each do |layout, path|
        visit path
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true),
          "#{layout} layout overflowed at #{width}px"
        expect(page).to be_axe_clean.excluding("#main-content") unless layout == :error
        expect(page).to be_axe_clean if layout == :error
        save_screenshot("#{layout}-shell-#{width}.png") if ENV["VISUAL_REVIEW"]
      end
    end
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  # button_to の form は block box を作るため、放置すると 1 つずつ行を占有して
  # 3 段になり、右寄せも効かなくなる。行数と右端で固定する。
  it "keeps the header actions on one right-aligned row on a phone" do
    skip "Chrome is required for viewport checks" unless ENV["CHROME_BINARY"].present?

    person = create(:person, display_name: "カーリア")
    user = create(:user, person: person)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: user.google_uid, info: { email: user.email }
    )

    begin
      [ 320, 390 ].each do |width|
        page.current_window.resize_to(width, 900)

        visit root_path
        expect_single_right_aligned_row(width, "未ログイン")

        sign_in_with_google
        page.current_window.resize_to(width, 900)
        visit root_path
        expect_right_aligned(width, "ログイン済み")
        expect(page).to have_no_css('header nav[aria-label="主要"] > form')

        click_button "メニュー"
        account_menu = find("#account-menu")
        expect(account_menu.all("a, button").last.text).to eq("ログアウト")
        expect(account_menu).to have_css("button.text-ui-error", text: "ログアウト")

        account_menu.click_button "ログアウト"
        expect(page).to have_link("新規登録")
      end
    ensure
      page.current_window.resize_to(1280, 900)
    end
  end

  # 高さが違う要素は items-center で top がずれるため、行の判定は中心線で行う。
  def expect_single_right_aligned_row(width, label)
    expect_right_aligned(width, label, rows: 1)
  end

  def expect_right_aligned(width, label, rows: nil)
    geometry = page.evaluate_script(<<~JS)
      (function () {
        var nav = document.querySelector('header nav[aria-label="主要"]');
        var items = [].slice.call(nav.querySelectorAll('a, button'));
        var centers = items.map(function (e) {
          var b = e.getBoundingClientRect();
          return Math.round((b.top + b.bottom) / 2 / 10);
        });
        var rights = items.map(function (e) { return Math.round(e.getBoundingClientRect().right); });
        return { rows: centers.filter(function (c, i) { return centers.indexOf(c) === i; }).length,
                 right: Math.max.apply(null, rights),
                 inner: window.innerWidth };
      })()
    JS

    expect(geometry["rows"]).to eq(rows),
      "#{width}px の#{label}ヘッダーで操作が #{geometry["rows"]} 段になっている" if rows
    expect(geometry["right"]).to be_within(1).of(geometry["inner"] - 16),
      "#{width}px の#{label}ヘッダーで右端が #{geometry["right"]}（幅 #{geometry["inner"]}）にあり右寄せになっていない"
  end
end
