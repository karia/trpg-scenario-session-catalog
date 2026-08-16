require "capybara/rails"

# 一覧の削除ボタンは見出しが「削除」だけになる。読み上げられる名前で引けるようにする。
Capybara.enable_aria_label = true

Capybara.register_driver :headless_chromium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = ENV.fetch("CHROME_BINARY")
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1440,1200")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by ENV["CHROME_BINARY"].present? ? :headless_chromium : :rack_test
  end
end
