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

    it "creates a session with its participants in one submission" do
      gm = create(:person, display_name: "回した人")
      player = create(:person, display_name: "遊んだ人")

      post manage_play_sessions_path, params: {
        play_session: {
          scenario_id: scenario.id,
          played_on: "2026-05-01",
          started_at: "20:00",
          status: "played",
          recording_url: "https://youtu.be/abc",
          cocofolia_url: "https://ccfolia.com/rooms/example",
          participations_attributes: [
            { person_id: gm.id, role: "gm" },
            { person_id: player.id, role: "player", character_name: "探索者A",
              character_sheet_url: "https://charasheet.example/1" }
          ]
        }
      }

      session = PlaySession.sole
      expect(session.scenario).to eq(scenario)
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

      expect(response.body).to include(edit_manage_play_session_path(other))
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

    it "updates a session" do
      session = create(:play_session, scenario:, status: :scheduled)

      patch manage_play_session_path(session), params: { play_session: { status: "played" } }

      expect(session.reload).to be_played
    end
  end
end
