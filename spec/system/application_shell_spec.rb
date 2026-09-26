require "rails_helper"

RSpec.describe "Application shell" do
  it "fits every layout at supported viewport widths and keeps the shell accessible" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    admin = create(:person, roles: %w[admin])
    user = create(:user, provider: "discord", person: admin)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord", uid: user.uid, info: { email: user.email }
    )

    sign_in_with_discord

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
    OmniAuth.config.mock_auth[:discord] = nil
    OmniAuth.config.test_mode = false
  end

  # button_to の form は block box を作るため、放置すると操作が 1 つずつ行を占有する。
  it "keeps the header actions on one right-aligned row on a phone" do
    skip "Chrome is required for viewport checks" unless ENV["CHROME_BINARY"].present?

    person = create(:person, display_name: "カーリア")
    user = create(:user, provider: "discord", person: person)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord", uid: user.uid, info: { email: user.email }
    )

    begin
      [ 320, 390 ].each do |width|
        page.current_window.resize_to(width, 900)

        visit root_path
        expect_single_right_aligned_row(width, "未ログイン")

        sign_in_with_discord
        page.current_window.resize_to(width, 900)
        visit root_path
        expect_single_right_aligned_row(width, "ログイン済み")
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
    expect(page).to have_css('header a[href="/"]')

    geometry = page.evaluate_script(<<~JS)
      (function () {
        var nav = document.querySelector('header nav[aria-label="主要"]');
        var items = [ document.querySelector('header a[href="/"]') ]
          .concat([].slice.call(nav.querySelectorAll('a, button')))
          .filter(function (e) { return !e.closest('#account-menu'); });
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

    expect(geometry["rows"]).to eq(1),
      "#{width}px の#{label}ヘッダーが #{geometry["rows"]} 段になっている"
    expect(geometry["right"]).to be_within(1).of(geometry["inner"] - 16),
      "#{width}px の#{label}ヘッダーで右端が #{geometry["right"]}（幅 #{geometry["inner"]}）にあり右寄せになっていない"
  end
end
