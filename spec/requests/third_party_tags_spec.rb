require "rails_helper"

RSpec.describe "Third party tags" do
  around do |example|
    ClimateControl.modify(ADSENSE_CLIENT_ID: "ca-pub-test") { example.run }
  end

  it "renders the analytics and ad tags for an anonymous visitor" do
    SiteSetting.current.update!(google_analytics_measurement_id: "G-TEST123")

    get root_path

    expect(response.body).to include("googletagmanager.com/gtag/js?id=G-TEST123")
    expect(response.body).to include("adsbygoogle.js?client=ca-pub-test")
  end

  it "does not render analytics when the measurement ID is empty" do
    get root_path

    expect(response.body).not_to include("googletagmanager.com")
  end

  it "renders neither once a visitor signs in, even before they are linked" do
    SiteSetting.current.update!(google_analytics_measurement_id: "G-TEST123")
    sign_in_as create(:user, person: nil)

    get root_path

    expect(response.body).not_to include("googletagmanager.com")
    expect(response.body).not_to include("adsbygoogle")
  end
end
