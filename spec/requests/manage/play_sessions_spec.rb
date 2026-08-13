require "rails_helper"

RSpec.describe "Manage::PlaySessions" do
  let(:scenario) { create(:scenario, title: "見本シナリオ") }

  describe "access" do
    it "answers 404 to an anonymous visitor" do
      get manage_play_sessions_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a person with no role" do
      sign_in_as create(:person)

      get manage_play_sessions_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a plain player, whose public index? would otherwise allow it" do
      sign_in_as create(:person)

      get manage_play_sessions_path

      expect(response).to have_http_status(:not_found)
    end

    it "lets a GM in" do
      sign_in_as create(:person, roles: %w[gm])

      get manage_play_sessions_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "as a GM" do
    before { sign_in_as create(:person, roles: %w[gm]) }

    it "provides system-specific role labels when creating a session" do
      scenario.game_systems << create(:game_system, game_master_label: "KP")

      get manage_play_sessions_path

      page = Capybara.string(response.body)
      form = page.find('[data-controller="participation-roles"]')
      labels = JSON.parse(form["data-participation-roles-labels-value"])
      expect(labels.fetch(scenario.id.to_s)).to eq("gm" => "KP", "sub_gm" => "サブKP")
      expect(page).to have_css('[data-action="change->participation-roles#update"]')
    end

    it "creates a session with its participants in one submission" do
      gm = create(:person, display_name: "回した人")
      player = create(:person, display_name: "遊んだ人")

      post manage_play_sessions_path, params: {
        play_session: {
          scenario_id: scenario.id,
          session_schedules_attributes: [
            {
              scheduled_on: "2026-05-01",
              started_at: "20:00",
              recording_links_attributes: [
                { url: "https://youtu.be/abc" },
                { url: "https://youtu.be/def" }
              ]
            },
            { scheduled_on: "2026-05-03", started_at: "20:00" }
          ],
          cocofolia_url: "https://ccfolia.com/rooms/example",
          participations_attributes: [
            { person_id: gm.id, role: "gm" },
            { person_id: player.id, role: "player", character_name: "探索者A",
              character_sheet_url: "https://charasheet.example/1" }
          ]
        }
      }

      session = PlaySession.sole
      expect(response).to redirect_to(play_session_path(session))
      expect(session.scenario).to eq(scenario)
      expect(session.session_schedules.map(&:scheduled_on)).to eq([
        Date.new(2026, 5, 1), Date.new(2026, 5, 3)
      ])
      expect(session.session_schedules.first.recording_links.map(&:url)).to eq(
        %w[https://youtu.be/abc https://youtu.be/def]
      )
      expect(session).to have_attributes(
        played_on: Date.new(2026, 5, 1), recording_url: "https://youtu.be/abc"
      )
      expect(session.participations.map(&:role)).to contain_exactly("gm", "player")
      expect(session.cocofolia_url).to eq("https://ccfolia.com/rooms/example")
      expect(session.participations.find(&:player?).character_sheet_url).to eq("https://charasheet.example/1")
    end

    it "re-renders when the scenario is missing" do
      post manage_play_sessions_path, params: { play_session: { scenario_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(PlaySession.count).to eq(0)
    end

    # シナリオ名はフォームの選択肢にも出るため、一覧に並んだことは編集リンクで判定する。
    it "lists every session regardless of who played, so a GM can maintain them" do
      other = create(:play_session)
      other.participations.create!(person: create(:person), role: :gm)

      get manage_play_sessions_path

      expect(response.body).to include(play_session_path(other), edit_manage_play_session_path(other))
    end

    it "carries no explanation under the title" do
      get manage_play_sessions_path

      expect(response.body).not_to include("公開範囲に関わらず")
    end

    it "shows the note, which the reader-facing scope would hide" do
      session = create(:play_session, scenario:, note: "覚え書きの見本")

      get edit_manage_play_session_path(session)

      expect(response.body).to include("覚え書きの見本")
    end

    it "uses the scenario's labels in the role options" do
      scenario.game_systems << create(:game_system, game_master_label: "DL")
      session = create(:play_session, scenario:)
      session.participations.create!(person: create(:person), role: :gm)

      get edit_manage_play_session_path(session)

      options = Capybara.string(response.body).all('select[name*="[role]"] option').map(&:text).uniq
      expect(options).to eq([ "役割", "DL", "PL", "サブDL" ])
    end

    it "renders the edit form" do
      session = create(:play_session, scenario:)

      get edit_manage_play_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ココフォリアリンク", "play_session[cocofolia_url]")
    end

    it "re-renders instead of raising when the scenario is cleared on update" do
      session = create(:play_session, scenario:)

      patch manage_play_session_path(session), params: { play_session: { scenario_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session.reload.scenario).to eq(scenario)
    end

    it "refuses the same person on two rows instead of raising" do
      person = create(:person)

      post manage_play_sessions_path, params: {
        play_session: {
          scenario_id: scenario.id,
          participations_attributes: [
            { person_id: person.id, role: "gm" },
            { person_id: person.id, role: "player" }
          ]
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(PlaySession.count).to eq(0)
    end

    it "ignores a row that was added but never filled in" do
      post manage_play_sessions_path, params: {
        play_session: {
          scenario_id: scenario.id,
          participations_attributes: [
            { person_id: create(:person).id, role: "gm" },
            { person_id: "", role: "" }
          ]
        }
      }

      expect(PlaySession.sole.participations.count).to eq(1)
    end

    it "removes a participant marked for removal" do
      session = create(:play_session, scenario:)
      participation = session.participations.create!(person: create(:person), role: :player)

      patch manage_play_session_path(session), params: {
        play_session: { participations_attributes: [ { id: participation.id, _destroy: "1" } ] }
      }

      expect(session.reload.participations).to be_empty
    end

    it "deletes a session" do
      session = create(:play_session, scenario:)

      expect { delete manage_play_session_path(session) }.to change(PlaySession, :count).by(-1)
    end

    it "updates and removes nested schedules" do
      session = create(:play_session, scenario:)
      schedule = create(:session_schedule, play_session: session)

      patch manage_play_session_path(session), params: {
        play_session: { session_schedules_attributes: [ { id: schedule.id, _destroy: "1" } ] }
      }

      expect(response).to redirect_to(play_session_path(session))
      expect(session.reload.session_schedules).to be_empty
    end
  end

  describe "as an admin who is not a GM" do
    let(:session) do
      create(:play_session, scenario:, cocofolia_url: "https://ccfolia.com/rooms/participant-only")
    end

    before { sign_in_as create(:person, roles: %w[admin]) }

    it "keeps the Cocofolia URL out of the edit form" do
      get edit_manage_play_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("ココフォリアリンク", "play_session[cocofolia_url]",
        "https://ccfolia.com/rooms/participant-only")
    end

    it "does not update the Cocofolia URL from a crafted request" do
      patch manage_play_session_path(session), params: {
        play_session: { cocofolia_url: "https://ccfolia.com/rooms/changed-by-admin" }
      }

      expect(session.reload.cocofolia_url).to eq("https://ccfolia.com/rooms/participant-only")
    end
  end
end
