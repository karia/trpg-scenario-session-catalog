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

  attr_reader :view, :order, :authors, :game_systems, :player_count, :author_name

  def initialize(scope, params)
    @scope = scope
    @view = params[:view].to_s.presence_in(VIEWS) || VIEWS.first
    @order = params[:order].to_s.presence_in(ORDERS.keys)
    author_ids = Array(params[:author_ids].presence || params[:author_id]).map(&:to_s)
    @author_name = params[:author_name].to_s.strip
    added_author = Author.find_by(id: author_id_for_name(author_name))
    author_ids << added_author.id.to_s if added_author
    @author_name_error = author_name.present? && added_author.nil?
    @authors = Author.where(id: author_ids).order(:name).to_a
    game_system_ids = Array(params[:game_system_ids].presence || params[:game_system_id]).map(&:to_s)
    @game_systems = GameSystem.where(id: game_system_ids).order(:name).to_a
    @player_count = params[:player_count].to_s.to_i.then { |count| count if count.positive? }
  end

  def scenarios = ordered(filtered)

  def filtered? = authors.any? || game_systems.any? || player_count.present?

  def author_options = Author.where(id: author_option_ids).order(:name)

  def author_suggestions
    selected_ids = authors.map(&:id)
    author_names.filter_map { |name, ids| name if ids.one? && ids.intersect?(selected_ids) == false }.sort
  end

  def author_name_error? = @author_name_error

  def game_system_options = GameSystem.joins(:scenarios).merge(@scope).distinct.order(:name)

  def params(overrides = {})
    {
      view: (view unless view == VIEWS.first),
      author_ids: (authors.map(&:id) if authors.any?),
      game_system_ids: (game_systems.map(&:id) if game_systems.any?),
      player_count:, order:
    }.merge(overrides).compact
  end

  private
    def author_option_ids
      @author_option_ids ||= Author.joins(:scenarios).merge(@scope).distinct.reorder(nil).pluck(:id)
    end

    def author_names
      names = Hash.new { |hash, key| hash[key] = [] }
      Author.where(id: author_option_ids).pluck(:name, :id).each { |name, id| names[name] << id }
      AuthorAlias.where(author_id: author_option_ids, visible: true).pluck(:name, :author_id).each do |name, author_id|
        names[name] << author_id
      end
      names.transform_values(&:uniq)
    end

    def author_id_for_name(name)
      ids = author_names.fetch(name, [])
      ids.first if ids.one?
    end

    def filtered
      relation = @scope
      if authors.any?
        relation = relation.where(id: ScenarioAuthor.where(author_id: authors.map(&:id)).select(:scenario_id))
      end
      if game_systems.any?
        relation = relation.where(id: ScenarioGameSystem.where(game_system_id: game_systems.map(&:id)).select(:scenario_id))
      end
      return relation unless player_count

      if player_count == 5
        return relation.where("scenarios.player_count_max IS NULL OR scenarios.player_count_max >= 5")
      end

      relation
        .where(player_count_min: ..player_count)
        .where("scenarios.player_count_max IS NULL OR scenarios.player_count_max >= :count", count: player_count)
    end

    def ordered(relation)
      return relation.gm_ordered unless order

      relation.order(ORDERS.fetch(order), :title, :id)
    end
end
