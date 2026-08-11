require "rails_helper"

RSpec.describe "The scenario list" do
  let!(:scenario) do
    create(
      :scenario,
      title: "見本シナリオ",
      recommendation: 5,
      player_count_min: 3,
      player_count_max: 3,
      duration_min_hours: 6,
      duration_max_hours: 8,
      game_systems: [ create(:game_system, name: "見本システム") ],
      authors: [ create(:author, name: "見本作者") ]
    ).tap { |s| s.purchase_links.create!(label: "BOOTH", url: "https://example.com/items/1") }
  end

  describe "the default view" do
    it "is the table, which is what the spreadsheet gave" do
      get root_path

      expect(response.body).to include("<table")
    end

    it "shows the title, author, system, player count and duration" do
      get root_path

      expect(response.body).to include("見本シナリオ", "見本作者", "見本システム", "3人", "6時間〜8時間")
    end

    it "links the title to the scenario and the purchase label to the shop" do
      get root_path

      expect(response.body).to include(scenario_path(scenario))
      expect(response.body).to include("https://example.com/items/1")
    end

    it "leaves a column blank rather than inventing a value" do
      create(:scenario, title: "空欄だらけ")

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("空欄だらけ")
      expect(response.body).not_to include("未設定")
    end
  end

  describe "the heading" do
    it "counts the scenarios beside the title" do
      create(:scenario, title: "もう1本")

      get root_path

      expect(response.body[%r{<h1.*?</h1>}m]).to include("（全2件）")
    end

    it "carries no explanation under the title" do
      get root_path

      expect(response.body).not_to include("人数と目安時間から選べます")
    end
  end

  describe "switching" do
    it "offers a link to the jacket view" do
      get root_path

      expect(response.body).to include(root_path(view: "gallery"))
    end

    it "shows the jackets when asked" do
      get root_path(view: "gallery")

      expect(response.body).not_to include("<table")
      expect(response.body).to include("aspect-3/4")
    end

    it "offers a link back to the table" do
      get root_path(view: "gallery")

      expect(response.body).to include(root_path(view: "table"))
    end

    it "falls back to the table for an unknown value" do
      get root_path(view: "nonsense")

      expect(response.body).to include("<table")
    end
  end

  describe "the recommendation" do
    # 星や見出しだけでなく、属性や生の値として漏れていないかも見る。
    it "is absent from the list" do
      get root_path

      expect(response.body).not_to include("★", "おすすめ度")
      expect(response.body).not_to match(/recommendation/i)
    end

    it "is absent from the jacket view" do
      get root_path(view: "gallery")

      expect(response.body).not_to include("★")
      expect(response.body).not_to match(/recommendation/i)
    end

    it "is absent from the scenario page" do
      get scenario_path(scenario)

      expect(response.body).not_to include("★", "おすすめ度", "回したことない")
      expect(response.body).not_to match(/recommendation/i)
    end

    # 並び順は position が持つようになった（issue #41）。入力欄も残さない。
    it "no longer orders the list" do
      create(:scenario, title: "未評価", recommendation: nil)
      create(:scenario, title: "高評価", recommendation: 5)

      body = (get(root_path) && response.body)

      expect(body.index("未評価")).to be < body.index("高評価")
    end

    it "is absent from the edit screen" do
      sign_in_as create(:person, roles: %w[gm])

      get edit_manage_scenario_path(scenario)

      expect(response.body).not_to include("おすすめ度")
      expect(Capybara.string(response.body)).to have_no_css('select[name="scenario[recommendation]"]')
    end
  end

  describe "the order the GM arranged" do
    # 作成順と期待順をずらす。並べ替えを外すと落ちるようにする。
    it "is what the list opens with" do
      create(:scenario, title: "あとで作った先頭", position: 0)

      body = (get(root_path) && response.body)

      expect(body.index("あとで作った先頭")).to be < body.index("見本シナリオ")
    end

    it "is what the jacket view opens with too" do
      create(:scenario, title: "あとで作った先頭", position: 0)

      body = (get(root_path(view: "gallery")) && response.body)

      expect(body.index("あとで作った先頭")).to be < body.index("見本シナリオ")
    end
  end
end
