require "rails_helper"
require Rails.root.join("db/migrate/20260811020000_add_position_to_scenarios")

# 公開済みの並びを引き継ぐ移行であるため、移行後の順序をここで固定する。
RSpec.describe AddPositionToScenarios do
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

  # position を振るコールバックを通さずに旧形式の行を作る。
  def insert_legacy(title, attributes = {})
    now = Time.current
    Scenario.insert_all!([ attributes.merge(title:, player_count_min: 1, created_at: now, updated_at: now) ])
  end

  it "keeps the order the recommendation used to give" do
    insert_legacy("未評価", recommendation: nil)
    insert_legacy("いちおし", recommendation: 5)
    insert_legacy("ふつう", recommendation: 3)

    migrate(:up)

    expect(Scenario.order(:position).pluck(:title)).to eq([ "いちおし", "ふつう", "未評価" ])
  end

  it "breaks a tie on the recommendation by title" do
    insert_legacy("ま", recommendation: 5)
    insert_legacy("あ", recommendation: 5)

    migrate(:up)

    expect(Scenario.order(:position).pluck(:title)).to eq([ "あ", "ま" ])
  end

  it "gives every row a distinct position" do
    3.times { |n| insert_legacy("見本#{n}") }

    migrate(:up)

    expect(Scenario.pluck(:position).uniq.size).to eq(3)
  end

  # 入れ替えの途中は旧 Pod が position を知らないまま書き込む。落とさず末尾に置く。
  it "still takes a row from a pod that does not know about the position" do
    insert_legacy("先にあった行", recommendation: 5)

    migrate(:up)
    insert_legacy("旧 Pod が書いた行")

    expect(Scenario.order(:position).pluck(:title)).to eq([ "先にあった行", "旧 Pod が書いた行" ])
  end
end
