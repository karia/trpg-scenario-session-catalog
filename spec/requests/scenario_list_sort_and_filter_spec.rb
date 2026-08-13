require "rails_helper"

RSpec.describe "Sorting and filtering the scenario list" do
  let(:emoklore) { create(:game_system, name: "エモクロア") }
  let(:coc) { create(:game_system, name: "クトゥルフ") }
  let(:a_author) { create(:author, name: "あ作者") }
  let(:ma_author) { create(:author, name: "ま作者") }

  # 作成順と期待順をずらす。並べ替えを外すと落ちるようにする。
  let!(:middle) do
    create(:scenario, title: "なかほど", position: 2, player_count_min: 3, player_count_max: 4,
      duration_min_hours: 4, game_systems: [ coc ], authors: [ ma_author ])
  end
  let!(:first) do
    create(:scenario, title: "いちばん", position: 1, player_count_min: 1, player_count_max: 2,
      duration_min_hours: 0.5, game_systems: [ emoklore ], authors: [ a_author ])
  end
  let!(:last) do
    create(:scenario, title: "最後の見本", position: 3, player_count_min: 6, player_count_max: nil,
      duration_min_hours: nil, game_systems: [ coc, emoklore ], authors: [ a_author, ma_author ])
  end

  def expect_order(*titles)
    positions = titles.map { |title| response.body.index(title) }

    expect(positions).to eq(positions.compact.sort)
  end

  def order_menu
    Capybara.string(response.body).find('select[name="order"]')
  end

  it "puts the interactive list controls and results in one Turbo Frame" do
    get root_path

    frame = Capybara.string(response.body).find("turbo-frame#scenario_list")
    expect(frame).to have_button("1人")
    expect(frame).to have_select("並び順")
    expect(frame).to have_css("table")
  end

  it "still renders a complete HTML page on a cold request" do
    get root_path(order: "title_desc")

    expect(response.media_type).to eq("text/html")
    expect(response.body).to include("<html", "<title>", "turbo-frame")
    expect_order("最後の見本", "なかほど", "いちばん")
  end

  describe "sorting" do
    it "opens on the order the GM arranged" do
      get root_path

      expect_order("いちばん", "なかほど", "最後の見本")
    end

    it "orders by title" do
      get root_path(order: "title_asc")

      expect_order("いちばん", "なかほど", "最後の見本")
    end

    it "reverses the title order when asked" do
      get root_path(order: "title_desc")

      expect_order("最後の見本", "なかほど", "いちばん")
    end

    it "orders by the first author" do
      get root_path(order: "author_asc")

      expect_order("いちばん", "なかほど")
    end

    it "orders by the first game system" do
      get root_path(order: "game_system_asc")

      expect_order("いちばん", "なかほど")
    end

    it "orders by the smallest party the scenario takes" do
      get root_path(order: "player_count_asc")

      expect_order("いちばん", "なかほど", "最後の見本")
    end

    it "orders by the shortest session the scenario takes" do
      get root_path(order: "duration_asc")

      expect_order("いちばん", "なかほど")
    end

    it "keeps a scenario with no duration at the bottom in both directions" do
      get root_path(order: "duration_desc")

      expect_order("なかほど", "いちばん", "最後の見本")
    end

    it "lists a scenario with two authors once" do
      get root_path(order: "author_asc")

      expect(response.body.scan("最後の見本").size).to eq(1)
    end

    it "falls back to the GM order for an order it does not know" do
      get root_path(order: "title ASC) --")

      expect(response).to have_http_status(:ok)
      expect_order("いちばん", "なかほど", "最後の見本")
    end

    it "offers the GM order and every key in one menu" do
      get root_path

      expect(order_menu).to have_css("option", text: "GMのおすすめ順")
      expect(order_menu.all("option").map { |option| option[:value] })
        .to contain_exactly("", *ScenarioListing::ORDERS.keys)
    end

    it "marks the current order as selected" do
      get root_path(order: "player_count_desc")

      expect(order_menu.find("option[selected]")[:value]).to eq("player_count_desc")
    end

    it "no longer sorts from the headings" do
      get root_path

      expect(Capybara.string(response.body)).to have_no_css("th a")
    end

    it "uses an explicit submit button so changing the menu does not navigate unexpectedly" do
      get root_path

      expect(Capybara.string(response.body))
        .to have_css('form button[type="submit"]', text: "並べ替える")
    end

    it "keeps the current filter when the order changes" do
      get root_path(game_system_ids: [ emoklore.id ])

      expect(Capybara.string(response.body))
        .to have_css(%(form input[type="hidden"][name="game_system_ids[]"][value="#{emoklore.id}"]), visible: :all)
    end

    it "keeps the jacket view when the order changes" do
      get root_path(view: "gallery")

      expect(Capybara.string(response.body))
        .to have_css('form input[type="hidden"][name="view"][value="gallery"]', visible: :all)
    end

    it "keeps the current order when the filter is submitted" do
      get root_path(order: "title_desc")

      expect(Capybara.string(response.body))
        .to have_css('form input[type="hidden"][name="order"][value="title_desc"]', visible: :all)
    end
  end

  describe "filtering" do
    it "keeps the scenarios of any selected author" do
      get root_path(author_ids: [ ma_author.id, a_author.id ])

      expect(response.body).to include("いちばん", "なかほど", "最後の見本")
    end

    it "keeps the scenarios of any selected system" do
      get root_path(game_system_ids: [ emoklore.id, coc.id ])

      expect(response.body).to include("いちばん", "なかほど", "最後の見本")
    end

    it "keeps the scenarios that a party of that size can play" do
      get root_path(player_count: 3)

      expect(response.body).to include("なかほど")
      expect(response.body).not_to include("いちばん", "最後の見本")
    end

    it "counts a scenario with no upper bound as playable by a larger party" do
      get root_path(player_count: 9)

      expect(response.body).to include("最後の見本")
      expect(response.body).not_to include("いちばん", "なかほど")
    end

    it "treats five as the open-ended five-or-more bucket" do
      get root_path(player_count: 5)

      expect(response.body).to include("最後の見本")
      expect(response.body).not_to include("いちばん", "なかほど")
    end

    it "applies two filters at once" do
      get root_path(game_system_ids: [ emoklore.id ], player_count: 2)

      expect(response.body).to include("いちばん")
      expect(response.body).not_to include("なかほど", "最後の見本")
    end

    it "combines a filter with a sort" do
      get root_path(author_ids: [ ma_author.id ], order: "title_desc")

      expect_order("最後の見本", "なかほど")
    end

    it "ignores an author who does not exist" do
      get root_path(author_ids: [ 0 ])

      expect(response.body).to include("いちばん", "なかほど", "最後の見本")
    end

    it "offers toggle buttons for party size and systems" do
      get root_path

      document = Capybara.string(response.body)
      party_size = document.all("fieldset")[0]
      systems = document.all("fieldset")[1]

      expect(party_size).to have_css("legend", text: "人数")
      expect(party_size).to have_button("1人")
      expect(party_size).to have_button("5人以上")
      expect(party_size).to have_css("button", count: 5)
      expect(systems).to have_css("legend", text: "システム")
      expect(systems).to have_css("button", count: 2)
      expect(document).to have_no_css('select[name="game_system_id"]')
      expect(document).to have_no_css('input[type="number"][name="player_count"]')
    end

    it "marks selected buttons and links them to deselect themselves" do
      get root_path(player_count: 5, game_system_ids: [ emoklore.id ])

      document = Capybara.string(response.body)
      expect(document).to have_css('button[aria-pressed="true"]', text: "5人以上")
      expect(document).to have_css('button[aria-pressed="true"]', text: "エモクロア")
      selected_form = document.find("button", text: "5人以上").ancestor("form")
      expect(selected_form).to have_no_css('input[name="player_count"]', visible: :all)
    end

    it "offers author suggestions and removable selected author tags" do
      get root_path(author_ids: [ ma_author.id ])

      document = Capybara.string(response.body)
      expect(document).to have_css('input[aria-label="作者を追加"][list="author-suggestions"]')
      expect(document).to have_css('datalist#author-suggestions option[value="あ作者"]')
      expect(document).to have_css('input[type="hidden"][name="author_ids[]"]', visible: :all)
      expect(document).to have_css('a[aria-label="ま作者を解除"]')
    end

    it "accepts an author alias from the suggestions" do
      AuthorAlias.create!(author: ma_author, name: "ま先生")

      get root_path(author_name: "ま先生")

      expect(response.body).to include("なかほど", "最後の見本")
      expect(response.body).not_to include("いちばん")
    end

    it "rejects an alias shared by multiple authors" do
      AuthorAlias.create!(author: ma_author, name: "先生")
      AuthorAlias.create!(author: a_author, name: "先生")

      get root_path(author_name: "先生")

      document = Capybara.string(response.body)
      expect(document).to have_css('[role="alert"]', text: "候補から作者を選択してください")
      expect(document).to have_no_css('datalist option[value="先生"]')
    end

    it "does not suggest names belonging to a selected author" do
      AuthorAlias.create!(author: ma_author, name: "ま先生")

      get root_path(author_ids: [ ma_author.id ])

      document = Capybara.string(response.body)
      expect(document).to have_no_css('datalist option[value="ま作者"]')
      expect(document).to have_no_css('datalist option[value="ま先生"]')
    end

    it "identifies a name that was not selected from the author suggestions" do
      get root_path(author_name: "知らない作者")

      document = Capybara.string(response.body)
      expect(document).to have_css('[role="alert"]', text: "候補から作者を選択してください")
      expect(document).to have_css('input[name="author_name"][aria-invalid="true"]')
    end

    it "filters the jacket view as well" do
      get root_path(view: "gallery", game_system_ids: [ emoklore.id ])

      expect(response.body).not_to include("<table")
      expect(response.body).to include("いちばん")
      expect(response.body).not_to include("なかほど")
    end

    it "says so when nothing matches" do
      get root_path(player_count: 4, game_system_ids: [ emoklore.id ])

      expect(response.body).to include("条件に合うシナリオがありません")
    end
  end

  describe "what the list gives away" do
    it "keeps the recommendation out of the response whatever the filter" do
      get root_path(author_ids: [ ma_author.id ], order: "player_count_desc")

      expect(response.body).not_to include("★", "おすすめ度")
      expect(response.body).not_to match(/recommendation/i)
    end

    it "keeps the preparation note out of the response for an anonymous visitor" do
      middle.update!(preparation_note: "ネタバレ")

      get root_path(order: "title_asc")

      expect(response.body).not_to include("ネタバレ")
    end
  end
end
