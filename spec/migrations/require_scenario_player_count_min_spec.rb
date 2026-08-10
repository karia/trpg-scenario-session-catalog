require "rails_helper"
require Rails.root.join("db/migrate/20260811010000_require_scenario_player_count_min")

# 移行するのは公開済みの実データであるため、変換後の値をここで固定する。
RSpec.describe RequireScenarioPlayerCountMin do
  around do |example|
    verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    migrate(:down)
    example.run
  ensure
    ActiveRecord::Migration.verbose = verbose
    Scenario.reset_column_information
  end

  def migrate(direction)
    described_class.new.migrate(direction)
    Scenario.reset_column_information
  end

  def insert_legacy(title, attributes)
    Scenario.new(attributes.merge(title:)).save!(validate: false)
  end

  it "fills a missing minimum with a single player" do
    insert_legacy("制限なしの見本", player_count_min: nil, player_count_note: "制限なし")

    migrate(:up)

    expect(Scenario.find_by(title: "制限なしの見本").player_count_min).to eq(1)
  end

  it "leaves a minimum that is already recorded" do
    insert_legacy("4人の見本", player_count_min: 4, player_count_max: 5)

    migrate(:up)

    expect(Scenario.find_by(title: "4人の見本")).to have_attributes(player_count_min: 4, player_count_max: 5)
  end

  it "drops the note that carried 「程度」" do
    insert_legacy("程度の見本", player_count_min: 2, player_count_note: "程度")

    migrate(:up)

    expect(Scenario.column_names).not_to include("player_count_note")
  end

  it "stops the database taking a row without a minimum" do
    migrate(:up)

    expect { insert_legacy("下限なし", player_count_min: nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end
end
