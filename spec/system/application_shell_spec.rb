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
  it "keeps the signed-out header actions on one right-aligned row on a phone" do
    skip "Chrome is required for viewport checks" unless ENV["CHROME_BINARY"].present?

    [ 320, 390 ].each do |width|
      page.current_window.resize_to(width, 900)
      visit root_path

      geometry = page.evaluate_script(<<~JS)
        (function () {
          var nav = document.querySelector('header nav[aria-label="主要"]');
          var items = [].slice.call(nav.querySelectorAll('a, button'));
          var tops = items.map(function (e) { return Math.round(e.getBoundingClientRect().top); });
          var rights = items.map(function (e) { return Math.round(e.getBoundingClientRect().right); });
          return { rows: tops.filter(function (t, i) { return tops.indexOf(t) === i; }).length,
                   right: Math.max.apply(null, rights) };
        })()
      JS

      expect(geometry["rows"]).to eq(1), "#{width}px で操作が #{geometry["rows"]} 段になっている"
      expect(geometry["right"]).to be_within(1).of(width - 16),
        "#{width}px で右端が #{geometry["right"]} にあり右寄せになっていない"
    end
  ensure
    # 幅を戻さないと、同じセッションを使う後続の example が狭いままになる。
    page.current_window.resize_to(1280, 900)
  end
end
