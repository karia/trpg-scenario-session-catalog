require "rails_helper"

RSpec.describe "Manage::Scenarios" do
  let(:credentials) { ActionController::HttpAuthentication::Basic.encode_credentials("editor", "secret") }

  around do |example|
    ClimateControl.modify(MANAGE_USERNAME: "editor", MANAGE_PASSWORD: "secret") { example.run }
  end

  describe "without credentials" do
    it "answers 401 on the index" do
      get manage_scenarios_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 401 on create" do
      post manage_scenarios_path, params: { scenario: { title: "侵入" } }

      expect(response).to have_http_status(:unauthorized)
      expect(Scenario.count).to eq(0)
    end
  end

  describe "with credentials" do
    def authorized_get(path)
      get path, headers: { "HTTP_AUTHORIZATION" => credentials }
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
        headers: { "HTTP_AUTHORIZATION" => credentials },
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
        headers: { "HTTP_AUTHORIZATION" => credentials },
        params: { scenario: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Scenario.count).to eq(0)
    end

    it "updates a scenario" do
      scenario = create(:scenario, title: "旧題")

      patch manage_scenario_path(scenario),
        headers: { "HTTP_AUTHORIZATION" => credentials },
        params: { scenario: { title: "新題" } }

      expect(scenario.reload.title).to eq("新題")
    end
  end
end
