require "rails_helper"

RSpec.describe "SpoilerReveals" do
  let(:scenario) { create(:scenario, title: "見本シナリオ", preparation_note: "ネタバレを含む準備情報") }

  it "keeps the note out of the response for a visitor who has not signed in" do
    get scenario_path(scenario)

    expect(response.body).not_to include("ネタバレを含む準備情報")
  end

  it "keeps the note out of the response for a member who has not pressed the button" do
    sign_in_as create(:person)

    get scenario_path(scenario)

    expect(response.body).to include("シナリオ準備情報")
    expect(response.body).not_to include("ネタバレを含む準備情報")
  end

  it "refuses to record a reveal for an account with no person" do
    sign_in_as create(:user, person: nil)

    post scenario_spoiler_reveal_path(scenario)

    expect(response).to have_http_status(:not_found)
    expect(SpoilerReveal.count).to eq(0)
  end

  it "shows the note once the member presses the button" do
    person = create(:person)
    sign_in_as person

    post scenario_spoiler_reveal_path(scenario)
    get scenario_path(scenario)

    expect(response.body).to include("ネタバレを含む準備情報")
  end

  it "remembers the press across sessions, so another device sees it open" do
    person = create(:person)
    user = create(:user, person: person)
    sign_in_as user
    post scenario_spoiler_reveal_path(scenario)
    delete session_path

    sign_in_as user
    get scenario_path(scenario)

    expect(response.body).to include("ネタバレを含む準備情報")
  end

  it "does not open the note for a different member" do
    revealed_by = create(:person)
    sign_in_as revealed_by
    post scenario_spoiler_reveal_path(scenario)
    delete session_path

    sign_in_as create(:person)
    get scenario_path(scenario)

    expect(response.body).not_to include("ネタバレを含む準備情報")
  end

  it "replaces only the note area" do
    sign_in_as create(:person)

    post scenario_spoiler_reveal_path(scenario), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
  end
end
