require "rails_helper"

RSpec.describe "The site name" do
  it "names the site in the header" do
    get root_path

    header = response.body[%r{<header.*?</header>}m]

    expect(header).to include("TRPGカタログ")
    expect(header).not_to include("卓の記録")
  end

  it "names the site in the page title" do
    get root_path

    expect(response.body).to include("<title>シナリオ一覧 | TRPGカタログ</title>")
  end

  it "carries no subtitle beside the name" do
    get root_path

    expect(response.body).not_to include("シナリオとセッションのカタログ")
  end
end
