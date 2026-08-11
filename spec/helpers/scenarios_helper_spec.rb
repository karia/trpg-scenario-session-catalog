require "rails_helper"

RSpec.describe ScenariosHelper do
  describe "#scenario_order_options" do
    def options_of(listing) = Capybara.string("<select>#{helper.scenario_order_options(listing)}</select>").all("option")

    it "puts the GM order first, on the empty value" do
      options = options_of(ScenarioListing.new(Scenario.all, {}))

      expect(options.first).to have_text("GMのおすすめ順")
      expect(options.first[:value]).to eq("")
    end

    it "names both directions of every key" do
      labels = options_of(ScenarioListing.new(Scenario.all, {})).map(&:text)

      expect(labels).to include("シナリオ名（昇順）", "人数（少ない順）", "人数（多い順）", "目安時間（長い順）")
    end

    it "selects nothing but the GM order when no order is asked for" do
      selected = options_of(ScenarioListing.new(Scenario.all, {})).select { |option| option[:selected] }

      expect(selected.map { |option| option[:value] }).to eq([ "" ])
    end
  end

  describe "#player_count_label" do
    it "shows a single figure when both ends match" do
      expect(helper.player_count_label(build(:scenario, player_count_min: 3, player_count_max: 3))).to eq("3人")
    end

    it "shows a range" do
      expect(helper.player_count_label(build(:scenario, player_count_min: 4, player_count_max: 5))).to eq("4人〜5人")
    end

    it "does not read a missing maximum as an exact figure" do
      expect(helper.player_count_label(build(:scenario, player_count_min: 4, player_count_max: nil))).to eq("4人以上")
    end

    it "marks a one-sided maximum as an upper bound" do
      expect(helper.player_count_label(build(:scenario, player_count_min: nil, player_count_max: 5))).to eq("5人まで")
    end

    it "says unset when there is nothing to show" do
      expect(helper.player_count_label(build(:scenario, player_count_min: nil))).to eq("未設定")
    end
  end

  describe "#duration_label" do
    it "shows a range in hours" do
      scenario = build(:scenario, duration_min_hours: 6, duration_max_hours: 8)

      expect(helper.duration_label(scenario)).to eq("6時間〜8時間")
    end

    it "keeps 「30分」 in hours rather than switching units" do
      scenario = build(:scenario, duration_min_hours: 0.5, duration_max_hours: 1)

      expect(helper.duration_label(scenario)).to eq("0.5時間〜1時間")
    end

    it "shows a single figure when both ends match" do
      expect(helper.duration_label(build(:scenario, duration_min_hours: 2, duration_max_hours: 2))).to eq("2時間")
    end

    it "drops the trailing zero of a whole hour" do
      expect(helper.duration_label(build(:scenario, duration_min_hours: 11, duration_max_hours: 18)))
        .to eq("11時間〜18時間")
    end

    it "does not read a missing maximum as an exact figure" do
      expect(helper.duration_label(build(:scenario, duration_min_hours: 2.5, duration_max_hours: nil)))
        .to eq("2.5時間以上")
    end

    it "says unset when there is nothing to show" do
      expect(helper.duration_label(build(:scenario))).to eq("未設定")
    end
  end

  describe "#character_sheet_deadline_label" do
    it "translates the enum" do
      expect(helper.character_sheet_deadline_label(build(:scenario, character_sheet_deadline: :two_days_before)))
        .to eq("セッション前々日")
    end

    it "prefers the free-text note when the deadline does not fit the enum" do
      scenario = build(:scenario, character_sheet_deadline: :see_note, character_sheet_deadline_note: "継続の場合提出不要")

      expect(helper.character_sheet_deadline_label(scenario)).to eq("継続の場合提出不要")
    end

    it "says unset for 「-」 and a blank cell" do
      expect(helper.character_sheet_deadline_label(build(:scenario, character_sheet_deadline: nil))).to eq("未設定")
    end
  end
end
