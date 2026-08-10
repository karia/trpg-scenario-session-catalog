# 一覧の表示形式、並び順、絞り込みをまとめて受け取る。
# 並び順の式は許可リストに載せた定数だけを使い、params は鍵としてしか触らない。
class ScenarioListing
  VIEWS = %w[table gallery].freeze
  DIRECTIONS = %w[asc desc].freeze

  # 作者とシステムは多対多である。JOIN で並べると 1 シナリオが作者の数だけ現れるため、相関サブクエリで畳む。
  SORTS = {
    "title" => "scenarios.title",
    "author" => "(SELECT MIN(authors.name) FROM authors " \
                "INNER JOIN scenario_authors ON scenario_authors.author_id = authors.id " \
                "WHERE scenario_authors.scenario_id = scenarios.id)",
    "game_system" => "(SELECT MIN(game_systems.name) FROM game_systems " \
                     "INNER JOIN scenario_game_systems ON scenario_game_systems.game_system_id = game_systems.id " \
                     "WHERE scenario_game_systems.scenario_id = scenarios.id)",
    "player_count" => "scenarios.player_count_min",
    "duration" => "scenarios.duration_min_hours"
  }.freeze

  # プルダウンは値を 1 つしか送れないため、鍵と向きを 1 つの文字列にまとめる。
  ORDERS = SORTS.keys.product(DIRECTIONS).to_h { |sort, direction|
    [ "#{sort}_#{direction}", Arel.sql("#{SORTS.fetch(sort)} #{direction.upcase} NULLS LAST") ]
  }.freeze

  attr_reader :view, :order, :author, :game_system, :player_count

  def initialize(scope, params)
    @scope = scope
    @view = params[:view].to_s.presence_in(VIEWS) || VIEWS.first
    @order = params[:order].to_s.presence_in(ORDERS.keys)
    @author = Author.find_by(id: params[:author_id].to_s)
    @game_system = GameSystem.find_by(id: params[:game_system_id].to_s)
    @player_count = params[:player_count].to_s.to_i.then { |count| count if count.positive? }
  end

  def scenarios = ordered(filtered)

  def filtered? = author.present? || game_system.present? || player_count.present?

  def authors = Author.joins(:scenarios).merge(@scope).distinct

  def game_systems = GameSystem.joins(:scenarios).merge(@scope).distinct

  def params(overrides = {})
    {
      view: (view unless view == VIEWS.first),
      author_id: author&.id, game_system_id: game_system&.id, player_count:, order:
    }.merge(overrides).compact
  end

  private
    def filtered
      relation = @scope
      relation = relation.where(id: ScenarioAuthor.where(author_id: author.id).select(:scenario_id)) if author
      if game_system
        relation = relation.where(id: ScenarioGameSystem.where(game_system_id: game_system.id).select(:scenario_id))
      end
      return relation unless player_count

      relation
        .where(player_count_min: ..player_count)
        .where("scenarios.player_count_max IS NULL OR scenarios.player_count_max >= :count", count: player_count)
    end

    def ordered(relation)
      return relation.gm_ordered unless order

      relation.order(ORDERS.fetch(order), :title, :id)
    end
end
