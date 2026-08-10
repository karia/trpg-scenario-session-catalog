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
      expect(session.participations.find(&:player?).character_sheet_url).to eq("https://charasheet.example/1")
    end

    it "re-renders when the scenario is missing" do
      post manage_play_sessions_path, params: { play_session: { scenario_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(PlaySession.count).to eq(0)
    end

    it "lists every session regardless of who played, so a GM can maintain them" do
      other = create(:play_session)
      other.participations.create!(person: create(:person), role: :gm)

      get manage_play_sessions_path

      expect(response.body).to include(other.scenario.title)
    end

    it "updates a session" do
      session = create(:play_session, scenario:, status: :scheduled)

      patch manage_play_session_path(session), params: { play_session: { status: "played" } }

      expect(session.reload).to be_played
    end
  end
end
