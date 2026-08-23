require "rails_helper"

RSpec.describe "Application shell" do
  it "fits supported viewport widths and keeps the error page accessible" do
    skip "Chrome is required for viewport and axe checks" unless ENV["CHROME_BINARY"].present?

    visit play_sessions_path
    expect(page).to have_css("h1", text: "ページが見つかりませんでした")
    expect(page).to be_axe_clean

    [ 320, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      visit root_path
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true),
        "application shell overflowed at #{width}px"
      save_screenshot("application-shell-#{width}.png") if ENV["VISUAL_REVIEW"]
    end
  end
end
