require "rails_helper"

RSpec.describe "Error pages" do
  around do |example|
    original = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    example.run
  ensure
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = original
  end

  it "renders the site 404 page at an unknown URL" do
    get "/missing-page"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("ページが見つかりませんでした")
    expect(Capybara.string(response.body)).to have_link("トップページに戻る", href: root_path)
    expect(response).not_to be_redirect
  end

  it "renders the site 404 page when authorization hides a page" do
    get play_sessions_path

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("ページが見つかりませんでした")
  end

  it "renders the site 500 page" do
    post "/500"

    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to include("サーバーでエラーが発生しました")
    expect(Capybara.string(response.body)).to have_link("トップページに戻る", href: root_path)
    expect(response).not_to be_redirect
  end
end
