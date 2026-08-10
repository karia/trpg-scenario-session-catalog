require "rails_helper"

RSpec.describe "Manage::Scenarios" do
  describe "without a signed-in editor" do
    it "answers 404 to an anonymous visitor" do
      get manage_scenarios_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a user who is not linked to a person" do
      sign_in_as create(:user, person: nil)

      get manage_scenarios_path

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 to a person with no role" do
      sign_in_as create(:person)

      get manage_scenarios_path

      expect(response).to have_http_status(:not_found)
    end

    it "does not create a scenario for an anonymous visitor" do
      post manage_scenarios_path, params: { scenario: { title: "侵入" } }

      expect(response).to have_http_status(:not_found)
      expect(Scenario.count).to eq(0)
    end
  end

  describe "as a GM" do
    before { sign_in_as create(:person, roles: %w[gm]) }

    def authorized_get(path)
      get path
    end

    it "lists the scenarios" do
      create(:scenario, title: "カタシロ")

      authorized_get manage_scenarios_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("カタシロ")
    end

    it "creates a scenario with its systems, authors and links in one submission" do
      system = create(:game_system, name: "エモクロアTRPG")
      author = create(:author, name: "ディズム")

      post manage_scenarios_path,
        params: {
          scenario: {
            title: "変葬",
            game_system_ids: [ system.id ],
            author_ids: [ author.id ],
            player_count_min: 1,
            player_count_max: 1,
            duration_min_minutes: 120,
            duration_max_minutes: 180,
            recommendation: 4,
            character_sheet_deadline: "one_week_before",
            purchase_links_attributes: [ { label: "BOOTH", url: "https://booth.pm/ja/items/3129552" } ],
            stream_links_attributes: [ { label: "配信", url: "https://youtu.be/xyz" } ]
          }
        }

      scenario = Scenario.sole
      expect(scenario.title).to eq("変葬")
      expect(scenario.game_systems).to eq([ system ])
      expect(scenario.authors).to eq([ author ])
      expect(scenario.purchase_links.map(&:label)).to eq([ "BOOTH" ])
      expect(scenario.stream_links.map(&:url)).to eq([ "https://youtu.be/xyz" ])
    end

    it "re-renders the form when the title is missing" do
      post manage_scenarios_path,
        params: { scenario: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Scenario.count).to eq(0)
    end

    # セッションごと消えると参加記録が失われる。外部キーで止まっていた挙動を保つ。
    it "refuses to delete a scenario that still has sessions" do
      scenario = create(:scenario)
      create(:play_session, scenario: scenario)

      expect { delete manage_scenario_path(scenario) }.not_to change(Scenario, :count)
      expect(PlaySession.count).to eq(1)
    end

    it "deletes a scenario that has no sessions" do
      scenario = create(:scenario)

      expect { delete manage_scenario_path(scenario) }.to change(Scenario, :count).by(-1)
    end

    it "updates a scenario" do
      scenario = create(:scenario, title: "旧題")

      patch manage_scenario_path(scenario), params: { scenario: { title: "新題" } }

      expect(scenario.reload.title).to eq("新題")
    end
  end
end
