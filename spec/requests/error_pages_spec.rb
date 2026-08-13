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

  it "renders the site 404 page for a non-HTML authorization request" do
    get play_sessions_path, as: :json

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("ページが見つかりませんでした")
  end

  it "renders the site 500 page through the exception application" do
    env = Rack::MockRequest.env_for("/original-path")
    env["PATH_INFO"] = "/500"
    env["action_dispatch.original_path"] = "/original-path"
    env["action_dispatch.exception"] = RuntimeError.new("unexpected failure")

    status, headers, body = Rails.application.config.exceptions_app.call(env)
    response_body = body.each.to_a.join

    expect(status).to eq(500)
    expect(headers).not_to include("location")
    expect(response_body).to include("サーバーでエラーが発生しました")
    expect(Capybara.string(response_body)).to have_link("トップページに戻る", href: root_path)
    expect(env["action_dispatch.original_path"]).to eq("/original-path")
  end
end
