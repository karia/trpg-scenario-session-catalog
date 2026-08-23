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

    it "separates purchase links and presents edit and delete as paired buttons" do
      scenario.purchase_links.create!(label: "TALTO", url: "https://example.com/items/2")
      sign_in_as create(:person, roles: %w[admin])

      get root_path

      page = Capybara.string(response.body)
      expect(page).to have_css("td div.gap-x-2 a", text: "BOOTH")
      expect(page).to have_css("td div.gap-x-2 a", text: "TALTO")
      expect(page).to have_css(%(a[href="#{edit_scenario_path(scenario)}"].bg-ui-surface-solid), text: "編集")
      expect(page).to have_button("削除")
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
    it "names the administrator whose scenarios are listed" do
      create(:person, display_name: "カーリア", roles: %w[admin])

      get root_path

      expect(response.body).to include("カーリアが所持するTRPGシナリオ一覧")
    end

    it "counts the scenarios beside the title" do
      create(:scenario, title: "もう1本")

      get root_path

      expect(Capybara.string(response.body)).to have_css('[role="status"]', text: "全2件")
    end

    it "carries no explanation under the title" do
      get root_path

      expect(response.body).not_to include("人数と目安時間から選べます")
    end

    it "opens new registration outside the filtered-list Turbo Frame" do
      sign_in_as create(:person, roles: %w[gm])

      get root_path

      expect(Capybara.string(response.body)).to have_css(
        %(a[href="#{new_scenario_path}"][data-turbo-frame="_top"]), text: "新規登録"
      )
    end
  end

  describe "switching" do
    it "offers a link to the jacket view" do
      get root_path

      expect(response.body).to include(root_path(view: "gallery"))
    end

    it "keeps the two views meaningfully different on narrow screens" do
      get root_path

      page = Capybara.string(response.body)
      expect(page).to have_css("ul.lg\\:hidden dl", visible: :all)
      expect(page).to have_css("table", visible: :all)

      get root_path(view: "gallery")

      expect(Capybara.string(response.body)).to have_css(".aspect-3\\/4", visible: :all)
    end

    it "shows the jackets when asked" do
      scenario.jacket.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "jacket.png", content_type: "image/png"
      )

      get root_path(view: "gallery")

      expect(response.body).not_to include("<table")
      expect(response.body).to include("aspect-3/4")
      expect(Capybara.string(response.body)).to have_css("img.object-contain")
      expect(Capybara.string(response.body)).not_to have_css("img.object-cover")
    end

    it "uses the imported BOOTH image when no jacket is attached" do
      scenario.booth_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "booth-fallback.png", content_type: "image/png"
      )

      get root_path(view: "gallery")

      expect(response.body).to include("booth-fallback.png")
    end

    it "prefers the uploaded jacket to the imported BOOTH image" do
      scenario.jacket.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "uploaded-jacket.png", content_type: "image/png"
      )
      scenario.booth_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/dot.png")), filename: "booth-fallback.png", content_type: "image/png"
      )

      get root_path(view: "gallery")

      expect(response.body).to include("uploaded-jacket.png")
      expect(response.body).not_to include("booth-fallback.png")
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

      get edit_scenario_path(scenario)

      expect(response.body).not_to include("おすすめ度")
      expect(Capybara.string(response.body)).to have_no_css('select[name="scenario[recommendation]"]')
    end
  end

  describe "scenario status" do
    let!(:admin) { create(:person, roles: %w[admin]) }

    it "uses each scenario's game master label for GM experience" do
      scenario.game_systems.first.update!(game_master_label: "DL")
      create(:scenario_status, person: admin, scenario:, gm_experienced: true)

      get root_path

      expect(Capybara.string(response.body).find("tr", text: scenario.title)).to have_text("DL経験あり")
    end

    it "shows only the administrator's highest-priority label" do
      create(:scenario_status, person: admin, scenario:, pl_experienced: true, read: true)
      other = create(:person, roles: %w[gm])
      create(:scenario_status, person: other, scenario:, gm_experienced: true)

      get root_path

      page = Capybara.string(response.body)
      expect(page).to have_css("th", text: "ステータス")
      expect(page.find("tr", text: scenario.title)).to have_text("PL経験あり")
      expect(page.find("tr", text: scenario.title)).to have_no_text(/GM経験あり|シナリオ既読/)
    end

    it "falls back to ownership when the administrator has no positive status" do
      create(:scenario_status, person: admin, scenario:)

      get root_path

      expect(Capybara.string(response.body).find("tr", text: scenario.title)).to have_text("シナリオ所持")
    end

    it "offers yes and no radio buttons for all three values on the edit screen" do
      editor = create(:person, roles: %w[gm])
      create(:scenario_status, person: editor, scenario:, gm_experienced: true, read: true)
      sign_in_as editor

      get edit_scenario_path(scenario)

      page = Capybara.string(response.body)
      %w[gm_experienced pl_experienced read].each do |attribute|
        expect(page).to have_css(%(input[type="radio"][name="scenario_status[#{attribute}]"]), count: 2)
      end
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
