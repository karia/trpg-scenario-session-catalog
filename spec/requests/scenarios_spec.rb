require "rails_helper"

RSpec.describe "Scenarios" do
  describe "GET /" do
    it "is readable without signing in" do
      create(:scenario, title: "カタシロ")

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("カタシロ")
    end
  end

  describe "GET /scenarios/:id" do
    let(:scenario) do
      create(
        :scenario,
        title: "ロールシャッハシンドローム",
        synopsis: "あらすじ本文",
        preparation_note: "ネタバレを含む準備情報",
        game_systems: [ create(:game_system, name: "エモクロアTRPG") ],
        authors: [ create(:author, name: "ディズム") ]
      )
    end

    it "is readable without signing in" do
      get scenario_path(scenario)

      expect(response).to have_http_status(:ok)
    end

    it "shows the public fields" do
      scenario.purchase_links.create!(label: "BOOTH", url: "https://booth.pm/ja/items/1")
      scenario.stream_links.create!(label: "配信", url: "https://youtu.be/abc")

      get scenario_path(scenario)

      expect(response.body).to include("ロールシャッハシンドローム", "あらすじ本文", "エモクロアTRPG", "ディズム")
      expect(response.body).to include("https://booth.pm/ja/items/1", "https://youtu.be/abc")
    end

    it "keeps the preparation note out of the response entirely" do
      get scenario_path(scenario)

      expect(response.body).not_to include("ネタバレを含む準備情報")
    end

    it "puts the scenario name in the page title" do
      get scenario_path(scenario)

      expect(response.body).to include("<title>ロールシャッハシンドローム | 卓の記録</title>")
    end

    it "gives the JSON-LD block a nonce that matches the policy header" do
      get scenario_path(scenario)

      nonce = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
      expect(nonce).to be_present
      expect(response.body).to include(%(nonce="#{nonce}"))
    end

    it "escapes a title that would otherwise break out of the JSON-LD block" do
      scenario.update!(title: %(危険</script><script>alert(1)</script>))

      get scenario_path(scenario)

      expect(response.body).not_to include("</script><script>alert(1)")
    end

    it "renders a purchase link that has a label but no URL" do
      scenario.purchase_links.create!(label: "書籍購入者限定特典", url: nil)

      get scenario_path(scenario)

      expect(response.body).to include("書籍購入者限定特典")
    end
  end
end
