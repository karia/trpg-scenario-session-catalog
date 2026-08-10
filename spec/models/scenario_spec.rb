require "rails_helper"

RSpec.describe Scenario do
  it "requires a title" do
    expect(described_class.new(title: "")).not_to be_valid
  end

  describe "recommendation" do
    it "accepts 1 through 5" do
      expect(build(:scenario, recommendation: 5)).to be_valid
    end

    it "accepts nil for a scenario nobody has rated yet" do
      expect(build(:scenario, recommendation: nil)).to be_valid
    end

    it "rejects a value outside the star range" do
      expect(build(:scenario, recommendation: 6)).not_to be_valid
    end
  end

  describe "gm_experienced" do
    it "defaults to true" do
      expect(described_class.new.gm_experienced).to be(true)
    end

    it "records 「回したことない」 separately from an unrated scenario" do
      never_run = build(:scenario, gm_experienced: false, recommendation: nil)
      unrated = build(:scenario, gm_experienced: true, recommendation: nil)

      expect(never_run).to be_valid
      expect(unrated).to be_valid
      expect(never_run.gm_experienced).not_to eq(unrated.gm_experienced)
    end
  end

  describe "player count" do
    it "allows both ends to be blank for 「制限なし」" do
      scenario = build(:scenario, player_count_min: nil, player_count_max: nil, player_count_note: "制限なし")

      expect(scenario).to be_valid
    end

    it "rejects a maximum below the minimum" do
      expect(build(:scenario, player_count_min: 3, player_count_max: 2)).not_to be_valid
    end
  end

  describe "duration" do
    it "holds minutes so that 「30分～60分」 fits" do
      scenario = build(:scenario, duration_min_minutes: 30, duration_max_minutes: 60)

      expect(scenario).to be_valid
    end

    it "rejects a maximum below the minimum" do
      expect(build(:scenario, duration_min_minutes: 120, duration_max_minutes: 60)).not_to be_valid
    end
  end

  describe "character_sheet_deadline" do
    it "covers every value seen in the spreadsheet" do
      expect(described_class.character_sheet_deadlines.keys)
        .to match_array(%w[day_before two_days_before one_week_before not_required see_note])
    end

    it "treats 「-」 and a blank cell as unset" do
      expect(build(:scenario, character_sheet_deadline: nil)).to be_valid
    end
  end

  describe "associations" do
    it "takes more than one game system for 「CoC 6版&7版」" do
      scenario = create(:scenario, game_systems: [ create(:game_system, name: "CoC 6版"), create(:game_system, name: "CoC 7版") ])

      expect(scenario.game_systems.map(&:name)).to eq([ "CoC 6版", "CoC 7版" ])
    end

    it "takes more than one author for a jointly written scenario" do
      scenario = create(:scenario, authors: [ create(:author, name: "まだら牛"), create(:author, name: "ディズム") ])

      expect(scenario.authors.map(&:name)).to contain_exactly("まだら牛", "ディズム")
    end

    it "destroys its links when destroyed" do
      scenario = create(:scenario)
      scenario.purchase_links.create!(label: "BOOTH", url: "https://booth.pm/ja/items/1")
      scenario.stream_links.create!(label: "配信", url: "https://youtu.be/abc")

      expect { scenario.destroy }.to change(PurchaseLink, :count).by(-1).and change(StreamLink, :count).by(-1)
    end
  end
end
