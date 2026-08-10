require "rails_helper"

RSpec.describe "Third party tags" do
  around do |example|
    ClimateControl.modify(GA_MEASUREMENT_ID: "G-TEST", ADSENSE_CLIENT_ID: "ca-pub-test") { example.run }
  end

  it "renders the analytics and ad tags for an anonymous visitor" do
    get root_path

    expect(response.body).to include("googletagmanager.com/gtag/js?id=G-TEST")
    expect(response.body).to include("adsbygoogle.js?client=ca-pub-test")
  end

  it "renders neither once a visitor signs in, even before they are linked" do
    sign_in_as create(:user, person: nil)

    get root_path

    expect(response.body).not_to include("googletagmanager.com")
    expect(response.body).not_to include("adsbygoogle")
  end
end
