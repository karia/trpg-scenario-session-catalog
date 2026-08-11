require "rails_helper"

RSpec.describe "SpoilerReveals" do
  let(:scenario) { create(:scenario, title: "見本シナリオ", preparation_note: "ネタバレを含む準備情報") }

  it "keeps the note out of the response for a visitor who has not signed in" do
    get scenario_path(scenario)

    expect(response.body).to include("プレーヤー向け事前情報")
    expect(response.body).to include("GMが許可したログイン済メンバーのみ表示可能です。")
    expect(response.body).not_to include("ネタバレを含む準備情報")
  end

  it "keeps the note out of the response for a member who has not pressed the button" do
    sign_in_as create(:person)

    get scenario_path(scenario)

    expect(response.body).to include("プレーヤー向け事前情報")
    expect(response.body).to include("本編のネタバレはありませんが、購入しないとわからない情報等を含みます。GMから許可があった場合のみ開いてください。")
    expect(response.body).to include("プレーヤー向け事前情報を見る")
    expect(response.body).not_to include("ネタバレを開く")
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

    expect(response.body).to include("ネタバレを含む準備情報", "プレーヤー向け事前情報を閉じる")
  end

  it "hides the note again once the member closes it" do
    person = create(:person)
    sign_in_as person
    post scenario_spoiler_reveal_path(scenario)

    delete scenario_spoiler_reveal_path(scenario)
    get scenario_path(scenario)

    expect(response.body).to include("プレーヤー向け事前情報を見る")
    expect(response.body).not_to include("ネタバレを含む準備情報")
    expect(person.spoiler_reveals.where(scenario: scenario)).not_to exist
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

  it "replaces only the note area when closing" do
    person = create(:person)
    sign_in_as person
    post scenario_spoiler_reveal_path(scenario)

    delete scenario_spoiler_reveal_path(scenario), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("プレーヤー向け事前情報を見る")
  end
end
