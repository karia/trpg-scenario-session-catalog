require "rails_helper"

# 削除は取り返しがつかない。誰に導線が出るか、何が守られるかを画面ごとに固定する。
RSpec.describe "Deletions" do
  # Capybara 既定の HTML4 パーサはブラウザと違って p を閉じない。実際の入れ子で見る。
  def links_beside_delete_button(body, path)
    Nokogiri::HTML5(body).at_css("form[action='#{path}']").parent.css("> a").map { |link| link["href"] }
  end

  describe "DELETE /scenarios/:id" do
    it "removes a scenario for a GM" do
      sign_in_as create(:person, roles: %w[gm])
      scenario = create(:scenario)

      delete scenario_path(scenario)

      expect(response).to redirect_to(scenarios_path)
      expect(Scenario.exists?(scenario.id)).to be(false)
    end

    it "keeps a scenario that still has sessions and says why" do
      sign_in_as create(:person, roles: %w[gm])
      scenario = create(:scenario)
      create(:play_session, scenario:)

      delete scenario_path(scenario)

      expect(response).to redirect_to(scenarios_path)
      expect(flash[:alert]).to be_present
      expect(Scenario.exists?(scenario.id)).to be(true)
    end

    it "answers 404 to a member without an editor role" do
      sign_in_as create(:person)
      scenario = create(:scenario)

      delete scenario_path(scenario)

      expect(response).to have_http_status(:not_found)
      expect(Scenario.exists?(scenario.id)).to be(true)
    end
  end

  describe "DELETE /play_sessions/:id" do
    it "removes a session for a GM" do
      sign_in_as create(:person, roles: %w[gm])
      play_session = create(:play_session)

      delete play_session_path(play_session)

      expect(response).to redirect_to(play_sessions_path)
      expect(PlaySession.exists?(play_session.id)).to be(false)
    end

    it "answers 404 to a member without an editor role" do
      sign_in_as create(:person)
      play_session = create(:play_session)

      delete play_session_path(play_session)

      expect(response).to have_http_status(:not_found)
      expect(PlaySession.exists?(play_session.id)).to be(true)
    end
  end

  describe "DELETE /people/:id" do
    it "removes another member for an admin" do
      sign_in_as create(:person, roles: %w[admin])
      person = create(:person)

      delete person_path(person)

      expect(response).to redirect_to(people_path)
      expect(Person.exists?(person.id)).to be(false)
    end

    # 削除できるのは管理者だけだが、自分を消せば管理者が 0 人になりうる。
    it "answers 404 when an admin aims at themselves" do
      admin = create(:person, roles: %w[admin])
      sign_in_as admin

      delete person_path(admin)

      expect(response).to have_http_status(:not_found)
      expect(Person.exists?(admin.id)).to be(true)
    end

    it "removes another admin" do
      sign_in_as create(:person, roles: %w[admin])
      other = create(:person, roles: %w[admin])

      delete person_path(other)

      expect(Person.exists?(other.id)).to be(false)
    end

    it "answers 404 to a GM" do
      sign_in_as create(:person, roles: %w[gm])
      person = create(:person)

      delete person_path(person)

      expect(response).to have_http_status(:not_found)
      expect(Person.exists?(person.id)).to be(true)
    end

    # 参加記録ごと消えると、セッションから参加者が抜け落ちる。
    it "keeps a member who has taken part in a session and says why" do
      sign_in_as create(:person, roles: %w[admin])
      person = create(:person)
      create(:participation, person:)

      delete person_path(person)

      expect(response).to redirect_to(people_path)
      expect(flash[:alert]).to be_present
      expect(Person.exists?(person.id)).to be(true)
    end

    it "leaves the accounts of a deleted member unlinked rather than destroyed" do
      sign_in_as create(:person, roles: %w[admin])
      person = create(:person)
      user = create(:user, person:)

      delete person_path(person)

      expect(User.exists?(user.id)).to be(true)
      expect(user.reload.person).to be_nil
    end
  end

  describe "DELETE /manage/users/:id" do
    it "removes an unlinked account for an admin" do
      sign_in_as create(:person, roles: %w[admin])
      user = create(:user, person: nil)

      delete manage_user_path(user)

      expect(response).to redirect_to(manage_users_path)
      expect(User.exists?(user.id)).to be(false)
    end

    # 自分のログイン手段を消すと、その場で締め出される。
    it "answers 404 when an admin aims at their own account" do
      own = sign_in_as create(:person, roles: %w[admin])

      delete manage_user_path(own)

      expect(response).to have_http_status(:not_found)
      expect(User.exists?(own.id)).to be(true)
    end

    it "removes an account linked to another member" do
      sign_in_as create(:person, roles: %w[admin])
      user = create(:user, person: create(:person))

      delete manage_user_path(user)

      expect(User.exists?(user.id)).to be(false)
    end

    it "answers 404 to a GM" do
      sign_in_as create(:person, roles: %w[gm])
      user = create(:user, person: nil)

      delete manage_user_path(user)

      expect(response).to have_http_status(:not_found)
      expect(User.exists?(user.id)).to be(true)
    end
  end

  describe "the delete button on a detail screen" do
    it "is present for a GM on a scenario and absent for a plain member" do
      scenario = create(:scenario)

      sign_in_as create(:person, roles: %w[gm])
      get scenario_path(scenario)
      expect(response.body).to include("このシナリオを削除")

      sign_in_as create(:person)
      get scenario_path(scenario)
      expect(response.body).not_to include("このシナリオを削除")
    end

    it "is present for a GM on a session" do
      play_session = create(:play_session)
      sign_in_as create(:person, roles: %w[gm])

      get play_session_path(play_session)

      expect(response.body).to include("このセッションを削除")
    end

    it "is present for an admin on another member and absent on themselves" do
      admin = create(:person, roles: %w[admin])
      sign_in_as admin

      get person_path(create(:person))
      expect(response.body).to include("このメンバーを削除")

      get person_path(admin)
      expect(response.body).not_to include("このメンバーを削除")
    end

    it "is absent on a member for a GM" do
      sign_in_as create(:person, roles: %w[gm])

      get person_path(create(:person))

      expect(response.body).not_to include("このメンバーを削除")
    end

    it "is present for an admin on another account and absent on their own" do
      own = sign_in_as create(:person, roles: %w[admin])

      get manage_user_path(create(:user, person: nil))
      expect(response.body).to include("このアカウントを削除")

      get manage_user_path(own)
      expect(response.body).not_to include("このアカウントを削除")
    end

    it "is present for an admin on a group" do
      sign_in_as create(:person, roles: %w[admin])

      get manage_group_path(create(:group))

      expect(response.body).to include("このグループを削除")
    end

    it "is present for a GM on the master tables and absent for a plain member" do
      game_system = create(:game_system)
      author = create(:author)

      sign_in_as create(:person, roles: %w[gm])
      get game_system_path(game_system)
      expect(response.body).to include("このシステムを削除")
      get author_path(author)
      expect(response.body).to include("この作者を削除")

      sign_in_as create(:person)
      get game_system_path(game_system)
      expect(response.body).not_to include("このシステムを削除")
    end
  end

  describe "the delete button on a list screen" do
    it "is present for a GM on the scenario list and absent for a plain member" do
      scenario = create(:scenario)

      sign_in_as create(:person, roles: %w[gm])
      get scenarios_path
      expect(Capybara.string(response.body))
        .to have_button("#{scenario.title} を削除")

      sign_in_as create(:person)
      get scenarios_path
      expect(Capybara.string(response.body))
        .to have_no_button("#{scenario.title} を削除")
    end

    it "is present for a GM on the session list" do
      play_session = create(:play_session)
      sign_in_as create(:person, roles: %w[gm])

      get play_sessions_path

      expect(Capybara.string(response.body))
        .to have_button("#{play_session.scenario.title} の#{PlaySession.model_name.human}を削除")
    end

    it "is present for an admin on the member list, except on their own row" do
      admin = create(:person, roles: %w[admin], display_name: "管理者")
      person = create(:person, display_name: "ほかの人")
      sign_in_as admin

      get people_path

      page = Capybara.string(response.body)
      expect(page).to have_button("ほかの人 を削除")
      expect(page).to have_no_button("管理者 を削除")
    end

    # button_to は form を出す。form は開いている p を暗黙に閉じるため、
    # 行を p で囲むとボタンだけが行の外へ飛び出す。
    it "stays in the same row as the edit link" do
      sign_in_as create(:person, roles: %w[admin])
      member = create(:person)
      play_session = create(:play_session)
      scenario = play_session.scenario

      get people_path
      expect(links_beside_delete_button(response.body, person_path(member)))
        .to include(edit_person_path(member))

      get play_sessions_path
      expect(links_beside_delete_button(response.body, play_session_path(play_session)))
        .to include(edit_play_session_path(play_session))

      get root_path(view: "gallery")
      expect(links_beside_delete_button(response.body, scenario_path(scenario)))
        .to include(edit_scenario_path(scenario))
    end

    it "is present for an admin on the account list, except on their own row" do
      own = sign_in_as create(:person, roles: %w[admin])
      other = create(:user, person: nil, email: "other@example.com")

      get manage_users_path

      page = Capybara.string(response.body)
      expect(page).to have_button("other@example.com を削除")
      expect(page).to have_no_button("#{own.email} を削除")
    end
  end
end
