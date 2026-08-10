require "rails_helper"
require Rails.root.join("db/migrate/20260811010100_convert_scenario_duration_to_hours")

# 移行するのは公開済みの実データであるため、変換後の値をここで固定する。
# 目安の幅が縮むと「実際は超えていた」が起きるため、下限は切り捨て、上限は切り上げる。
RSpec.describe ConvertScenarioDurationToHours do
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

  def convert(title, min_minutes, max_minutes)
    Scenario.new(title:, player_count_min: 1,
      duration_min_minutes: min_minutes, duration_max_minutes: max_minutes).save!(validate: false)

    migrate(:up)

    Scenario.find_by(title:)
  end

  it "turns whole hours into whole hours" do
    expect(convert("3〜4時間", 180, 240)).to have_attributes(duration_min_hours: 3.0, duration_max_hours: 4.0)
  end

  it "turns half hours into half hours" do
    expect(convert("30分〜1時間", 30, 60)).to have_attributes(duration_min_hours: 0.5, duration_max_hours: 1.0)
  end

  it "widens a range that does not land on a half hour" do
    expect(convert("75分〜100分", 75, 100)).to have_attributes(duration_min_hours: 1.0, duration_max_hours: 2.0)
  end

  it "keeps a short scenario at half an hour rather than dropping it to zero" do
    expect(convert("20分", 20, 20)).to have_attributes(duration_min_hours: 0.5, duration_max_hours: 0.5)
  end

  it "leaves a blank end blank" do
    expect(convert("下限だけ", 120, nil)).to have_attributes(duration_min_hours: 2.0, duration_max_hours: nil)
  end

  it "leaves an untimed scenario untimed" do
    expect(convert("未計測", nil, nil)).to have_attributes(duration_min_hours: nil, duration_max_hours: nil)
  end

  it "drops the columns that held minutes" do
    migrate(:up)

    expect(Scenario.column_names).not_to include("duration_min_minutes", "duration_max_minutes")
  end
end
