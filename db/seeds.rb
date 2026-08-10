# 初期投入。何度流しても同じ結果になる。
# 実データは git に置かない。書式は db/seeds/scenarios.example.yml を見る。
# 投入後はこのサイトが正になり、以後の編集は画面から行う。
# seeds は複数回 load されうるため、定数ではなくメソッドで持つ。
def seed_attributes
  %w[
    player_count_min player_count_max
    duration_min_hours duration_max_hours
    recommendation gm_experienced
    character_restriction character_sheet_deadline character_sheet_deadline_note
    recommendation_note
  ]
end

def seed_file
  explicit = ENV["SCENARIOS_SEED_FILE"].presence
  return Pathname.new(explicit) if explicit

  real = Rails.root.join("db/seeds/scenarios.yml")
  real.exist? ? real : Rails.root.join("db/seeds/scenarios.example.yml")
end

def seed_scenario(row)
  scenario = Scenario.find_or_initialize_by(title: row.fetch("title"))
  scenario.assign_attributes(row.slice(*seed_attributes))
  scenario.game_systems = Array(row["game_systems"]).map { |name| GameSystem.find_or_create_by!(name:) }
  scenario.authors = Array(row["authors"]).map { |name| Author.find_or_create_by!(name:) }
  scenario.save!

  Array(row["purchase_links"]).each_with_index do |link, index|
    record = scenario.purchase_links.find_or_initialize_by(label: link.fetch("label"))
    record.update!(url: link["url"], position: index)
  end

  scenario
end

path = seed_file
YAML.load_file(path).each { |row| seed_scenario(row) }

puts "seeded from #{path.basename}: scenarios=#{Scenario.count} systems=#{GameSystem.count} authors=#{Author.count}"
