require "rails_helper"

RSpec.describe "Sitemap" do
  it "lists the public pages as XML" do
    scenario = create(:scenario, title: "カタシロ")

    get "/sitemap.xml"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/xml")
    expect(response.body).to include(root_url, scenario_url(scenario))
  end

  it "does not list the editing screens" do
    create(:scenario)

    get "/sitemap.xml"

    expect(response.body).not_to include("/manage")
  end

  it "answers 304 when nothing has changed since the last fetch" do
    create(:scenario)

    get "/sitemap.xml"
    etag = response.headers["ETag"]

    get "/sitemap.xml", headers: { "HTTP_IF_NONE_MATCH" => etag }

    expect(response).to have_http_status(:not_modified)
  end
end
