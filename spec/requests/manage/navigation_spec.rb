require "rails_helper"

RSpec.describe "Manage navigation" do
  let(:sections) do
    {
      "シナリオ" => "/manage/scenarios",
      "セッション" => "/manage/play_sessions",
      "システム" => "/manage/game_systems",
      "作者" => "/manage/authors",
      "メンバー" => "/manage/people",
      "グループ" => "/manage/groups",
      "アカウント" => "/manage/users"
    }
  end

  describe "an administrator" do
    before { sign_in_as create(:person, roles: %w[admin]) }

    # 権限の重複付与に頼らず、管理者だけで全操作できることを固定する。
    it "can open every manage screen without also holding the GM role" do
      sections.each_value do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path} answered #{response.status}"
      end
    end

    it "is offered a link to every section" do
      get "/manage/scenarios"

      sections.each_value { |path| expect(response.body).to include(path) }
    end

    it "can edit a session" do
      session = create(:play_session, status: :scheduled)

      patch manage_play_session_path(session), params: { play_session: { status: "played" } }

      expect(session.reload).to be_played
    end
  end

  describe "a GM" do
    before { sign_in_as create(:person, roles: %w[gm]) }

    it "reaches the content sections" do
      [ "/manage/scenarios", "/manage/play_sessions", "/manage/game_systems", "/manage/authors" ].each do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path} answered #{response.status}"
      end
    end

    it "is not offered the admin-only sections" do
      get "/manage/scenarios"

      expect(response.body).not_to include("/manage/people")
      expect(response.body).not_to include("/manage/groups")
      expect(response.body).not_to include("/manage/users")
    end
  end

  describe "the header" do
    it "offers the manage area to an editor" do
      sign_in_as create(:person, roles: %w[gm])

      get root_path

      expect(response.body).to include(manage_scenarios_path)
    end

    it "does not offer it to a person with no role" do
      sign_in_as create(:person)

      get root_path

      expect(response.body).not_to include("/manage/")
    end
  end
end
