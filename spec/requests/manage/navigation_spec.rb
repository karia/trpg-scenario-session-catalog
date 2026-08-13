require "rails_helper"

RSpec.describe "Manage navigation" do
  let(:sections) do
    {
      "シナリオ" => "/scenarios",
      "セッション" => "/play_sessions",
      "システム" => "/game_systems",
      "作者" => "/authors",
      "メンバー" => "/people",
      "グループ" => "/manage/groups",
      "アカウント" => "/manage/users",
      "サイト全体設定" => "/manage/site_setting"
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
      get root_path

      sections.each_value { |path| expect(response.body).to include(path) }
    end

    it "can edit a session" do
      session = create(:play_session)

      patch play_session_path(session), params: { play_session: { note: "管理者が更新" } }

      expect(session.reload.note).to eq("管理者が更新")
    end
  end

  describe "a GM" do
    before { sign_in_as create(:person, roles: %w[gm]) }

    it "reaches the content sections" do
      [ "/scenarios", "/play_sessions", "/game_systems", "/authors" ].each do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path} answered #{response.status}"
      end
    end

    it "is not offered the admin-only sections" do
      get root_path

      expect(response.body).not_to include("/manage/groups")
      expect(response.body).not_to include("/manage/users")
      expect(response.body).not_to include("/manage/site_setting")
    end
  end

  describe "the header" do
    it "puts the menu after the profile and sign-out controls and uses a popover" do
      person = create(:person)
      sign_in_as person

      get root_path

      page = Capybara.string(response.body)
      expect(page).to have_css('button[popovertarget="account-menu"]', text: "メニュー")
      expect(page).to have_css('nav#account-menu[popover][aria-label="アカウントメニュー"]')
      expect(response.body.index(person.display_name)).to be < response.body.index("popover")
      expect(response.body.index("ログアウト")).to be < response.body.index("popover")
    end

    it "offers the manage area to an editor" do
      sign_in_as create(:person, roles: %w[gm])

      get root_path

      expect(response.body).to include(scenario_order_index_path)
    end

    it "offers it to an administrator who does not also hold the GM role" do
      sign_in_as create(:person, roles: %w[admin])

      get root_path

      expect(response.body).to include(scenario_order_index_path)
    end

    it "does not offer it to a person with no role" do
      sign_in_as create(:person)

      get root_path

      expect(response.body).not_to include("/manage/")
    end

    it "does not offer it to a visitor who has not signed in" do
      get root_path

      expect(response.body).not_to include("/manage/")
    end
  end
end
