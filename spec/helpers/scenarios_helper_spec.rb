require "rails_helper"

RSpec.describe ScenariosHelper do
  describe "#player_count_label" do
    it "shows a single figure when both ends match" do
      expect(helper.player_count_label(build(:scenario, player_count_min: 3, player_count_max: 3))).to eq("3人")
    end

    it "shows a range" do
      expect(helper.player_count_label(build(:scenario, player_count_min: 4, player_count_max: 5))).to eq("4人〜5人")
    end

    it "does not read a one-sided minimum as an exact figure" do
      expect(helper.player_count_label(build(:scenario, player_count_min: 4, player_count_max: nil))).to eq("4人")
    end

    it "marks a one-sided maximum as an upper bound" do
      expect(helper.player_count_label(build(:scenario, player_count_min: nil, player_count_max: 5))).to eq("5人まで")
    end

    it "falls back to the note for 「制限なし」" do
      scenario = build(:scenario, player_count_min: nil, player_count_max: nil, player_count_note: "制限なし")

      expect(helper.player_count_label(scenario)).to eq("制限なし")
    end

    it "appends the note to the figures for 「1人推奨」" do
      scenario = build(:scenario, player_count_min: 1, player_count_max: 1, player_count_note: "推奨")

      expect(helper.player_count_label(scenario)).to eq("1人 推奨")
    end

    it "says unset when there is nothing to show" do
      expect(helper.player_count_label(build(:scenario))).to eq("未設定")
    end
  end

  describe "#duration_label" do
    it "keeps 「30分～60分」 in minutes rather than mixing units" do
      scenario = build(:scenario, duration_min_minutes: 30, duration_max_minutes: 60)

      expect(helper.duration_label(scenario)).to eq("30分〜60分")
    end

    it "uses hours once the range reaches two hours" do
      scenario = build(:scenario, duration_min_minutes: 360, duration_max_minutes: 480)

      expect(helper.duration_label(scenario)).to eq("6時間〜8時間")
    end

    it "handles 「11～18時間」" do
      scenario = build(:scenario, duration_min_minutes: 660, duration_max_minutes: 1080)

      expect(helper.duration_label(scenario)).to eq("11時間〜18時間")
    end

    it "shows a single figure when both ends match" do
      expect(helper.duration_label(build(:scenario, duration_min_minutes: 120, duration_max_minutes: 120))).to eq("2時間")
    end

    it "keeps an awkward range in minutes instead of fractional hours" do
      scenario = build(:scenario, duration_min_minutes: 75, duration_max_minutes: 100)

      expect(helper.duration_label(scenario)).to eq("75分〜100分")
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
