require "rails_helper"

# 実データは公開しないため、書式ごとの分岐だけを架空のシナリオで確かめる。
RSpec.describe "db/seeds.rb" do
  let(:fixture) { Rails.root.join("spec/fixtures/scenarios_seed.yml") }

  def load_seeds
    ClimateControl.modify(SCENARIOS_SEED_FILE: fixture.to_s) { Rails.application.load_seed }
  end

  before { load_seeds }

  it "loads every row in the file" do
    expect(Scenario.count).to eq(YAML.load_file(fixture).size)
  end

  it "can be run twice without duplicating anything" do
    counts = -> { [ Scenario.count, GameSystem.count, Author.count, PurchaseLink.count ] }
    before = counts.call

    load_seeds

    expect(counts.call).to eq(before)
  end

  it "attaches every system a scenario names" do
    scenario = Scenario.find_by(title: "二系統の見本")

    expect(scenario.game_systems.map(&:name)).to contain_exactly("見本システム 1版", "見本システム 2版")
  end

  it "attaches every author of a jointly written scenario" do
    scenario = Scenario.find_by(title: "二系統の見本")

    expect(scenario.authors.map(&:name)).to contain_exactly("見本作者", "共著の見本作者")
  end

  it "leaves the maximum blank for a scenario with no upper bound" do
    scenario = Scenario.find_by(title: "上限のない見本")

    expect(scenario.player_count_min).to eq(1)
    expect(scenario.player_count_max).to be_nil
  end

  it "distinguishes a scenario the GM has never run from an unrated one" do
    never_run = Scenario.find_by(title: "未実施の見本")
    unrated = Scenario.find_by(title: "未評価の見本")

    expect(never_run.gm_experienced).to be(false)
    expect(never_run.recommendation).to be_nil
    expect(unrated.gm_experienced).to be(true)
    expect(unrated.recommendation).to be_nil
  end

  it "keeps a deadline that does not fit the enum as a note" do
    scenario = Scenario.find_by(title: "期限が選択肢に無い見本")

    expect(scenario.character_sheet_deadline).to eq("see_note")
    expect(scenario.character_sheet_deadline_note).to eq("継続の場合提出不要")
  end

  it "records a purchase link that has no URL" do
    link = Scenario.find_by(title: "期限が選択肢に無い見本").purchase_links.sole

    expect(link.label).to eq("書籍購入者限定特典")
    expect(link.url).to be_nil
  end

  it "leaves every row valid" do
    expect(Scenario.all.reject(&:valid?)).to be_empty
  end

  it "ships a sample file that the loader accepts" do
    sample = Rails.root.join("db/seeds/scenarios.example.yml")
    expect(sample).to exist

    Scenario.destroy_all
    ClimateControl.modify(SCENARIOS_SEED_FILE: sample.to_s) { Rails.application.load_seed }

    expect(Scenario.count).to eq(YAML.load_file(sample).size)
  end
end
