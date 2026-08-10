require "rails_helper"

RSpec.describe "Sorting and filtering the scenario list" do
  let(:emoklore) { create(:game_system, name: "エモクロア") }
  let(:coc) { create(:game_system, name: "クトゥルフ") }
  let(:a_author) { create(:author, name: "あ作者") }
  let(:ma_author) { create(:author, name: "ま作者") }

  # 作成順と期待順をずらす。並べ替えを外すと落ちるようにする。
  let!(:middle) do
    create(:scenario, title: "なかほど", recommendation: 5, player_count_min: 3, player_count_max: 4,
      duration_min_hours: 4, game_systems: [ coc ], authors: [ ma_author ])
  end
  let!(:first) do
    create(:scenario, title: "いちばん", recommendation: 1, player_count_min: 1, player_count_max: 2,
      duration_min_hours: 0.5, game_systems: [ emoklore ], authors: [ a_author ])
  end
  let!(:last) do
    create(:scenario, title: "びり", recommendation: 3, player_count_min: 6, player_count_max: nil,
      duration_min_hours: nil, game_systems: [ coc, emoklore ], authors: [ a_author, ma_author ])
  end

  def expect_order(*titles)
    positions = titles.map { |title| response.body.index(title) }

    expect(positions).to eq(positions.compact.sort)
  end

  def link_queries
    Capybara.string(response.body).all("a", visible: :all).filter_map do |link|
      query = URI(link[:href]).query
      Rack::Utils.parse_query(query) if query
    end
  end

  describe "sorting" do
    it "orders by title" do
      get root_path(sort: "title", direction: "asc")

      expect_order("いちばん", "なかほど", "びり")
    end

    it "reverses the title order when asked" do
      get root_path(sort: "title", direction: "desc")

      expect_order("びり", "なかほど", "いちばん")
    end

    it "orders by the first author" do
      get root_path(sort: "author", direction: "asc")

      expect_order("いちばん", "なかほど")
    end

    it "orders by the first game system" do
      get root_path(sort: "game_system", direction: "asc")

      expect_order("いちばん", "なかほど")
    end

    it "orders by the smallest party the scenario takes" do
      get root_path(sort: "player_count", direction: "asc")

      expect_order("いちばん", "なかほど", "びり")
    end

    it "orders by the shortest session the scenario takes" do
      get root_path(sort: "duration", direction: "asc")

      expect_order("いちばん", "なかほど")
    end

    it "keeps a scenario with no duration at the bottom in both directions" do
      get root_path(sort: "duration", direction: "desc")

      expect_order("なかほど", "いちばん", "びり")
    end

    it "lists a scenario with two authors once" do
      get root_path(sort: "author", direction: "asc")

      expect(response.body.scan("びり").size).to eq(1)
    end

    it "falls back to the recommended order for a sort it does not know" do
      get root_path(sort: "recommendation) --", direction: "asc")

      expect(response).to have_http_status(:ok)
      expect_order("なかほど", "びり", "いちばん")
    end

    it "falls back to ascending for a direction it does not know" do
      get root_path(sort: "title", direction: "sideways")

      expect_order("いちばん", "なかほど", "びり")
    end

    it "offers the ascending order on a heading that is not sorted yet" do
      get root_path

      expect(link_queries).to include("sort" => "title", "direction" => "asc")
    end

    it "offers the opposite order on the heading that is sorted" do
      get root_path(sort: "title", direction: "asc")

      expect(link_queries).to include("sort" => "title", "direction" => "desc")
    end

    it "keeps the current filter when the heading is clicked" do
      get root_path(game_system_id: emoklore.id)

      expect(link_queries)
        .to include("game_system_id" => emoklore.id.to_s, "sort" => "title", "direction" => "asc")
    end

    it "keeps the jacket view when the heading is clicked" do
      get root_path(view: "gallery", sort: "title", direction: "asc")

      expect(link_queries).to include(hash_including("view" => "gallery", "sort" => "title"))
    end
  end

  describe "filtering" do
    it "keeps only the scenarios of one author" do
      get root_path(author_id: ma_author.id)

      expect(response.body).to include("なかほど", "びり")
      expect(response.body).not_to include("いちばん")
    end

    it "keeps only the scenarios of one system" do
      get root_path(game_system_id: emoklore.id)

      expect(response.body).to include("いちばん", "びり")
      expect(response.body).not_to include("なかほど")
    end

    it "keeps the scenarios that a party of that size can play" do
      get root_path(player_count: 3)

      expect(response.body).to include("なかほど")
      expect(response.body).not_to include("いちばん", "びり")
    end

    it "counts a scenario with no upper bound as playable by a larger party" do
      get root_path(player_count: 9)

      expect(response.body).to include("びり")
      expect(response.body).not_to include("いちばん", "なかほど")
    end

    it "applies two filters at once" do
      get root_path(game_system_id: emoklore.id, player_count: 2)

      expect(response.body).to include("いちばん")
      expect(response.body).not_to include("なかほど", "びり")
    end

    it "combines a filter with a sort" do
      get root_path(author_id: ma_author.id, sort: "title", direction: "desc")

      expect_order("びり", "なかほど")
    end

    it "ignores an author who does not exist" do
      get root_path(author_id: 0)

      expect(response.body).to include("いちばん", "なかほど", "びり")
    end

    it "offers a way to clear the filters" do
      get root_path(author_id: ma_author.id)

      expect(response.body).to include("絞り込みを解除")
    end

    it "does not offer to clear anything when nothing is filtered" do
      get root_path

      expect(response.body).not_to include("絞り込みを解除")
    end

    it "offers a menu of authors, systems and party sizes" do
      get root_path

      expect(response.body).to include('name="author_id"', 'name="game_system_id"', 'name="player_count"')
    end

    it "filters the jacket view as well" do
      get root_path(view: "gallery", game_system_id: emoklore.id)

      expect(response.body).not_to include("<table")
      expect(response.body).to include("いちばん")
      expect(response.body).not_to include("なかほど")
    end

    it "says so when nothing matches" do
      get root_path(player_count: 5, game_system_id: emoklore.id)

      expect(response.body).to include("条件に合うシナリオがありません")
    end
  end

  describe "what the list gives away" do
    it "keeps the recommendation out of the response whatever the filter" do
      get root_path(author_id: ma_author.id, sort: "player_count", direction: "desc")

      expect(response.body).not_to include("★", "おすすめ度")
      expect(response.body).not_to match(/recommendation/i)
    end

    it "keeps the preparation note out of the response for an anonymous visitor" do
      middle.update!(preparation_note: "ネタバレ")

      get root_path(sort: "title", direction: "asc")

      expect(response.body).not_to include("ネタバレ")
    end
  end
end
