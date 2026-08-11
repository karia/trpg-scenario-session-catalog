require "rails_helper"

RSpec.describe Scenario do
  describe "BOOTH image source" do
    it "uses the first BOOTH purchase URL" do
      scenario = create(:scenario)
      scenario.purchase_links.create!(label: "別サイト", url: "https://example.com/item", position: 1)
      scenario.purchase_links.create!(label: "後のBOOTH", url: "https://booth.pm/ja/items/2", position: 3)
      scenario.purchase_links.create!(label: "先のBOOTH", url: "https://shop.booth.pm/items/1", position: 2)

      expect(scenario.booth_purchase_url).to eq("https://shop.booth.pm/items/1")
    end
  end

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

  describe "position" do
    it "puts a new scenario at the end of the list the GM has arranged" do
      first = create(:scenario)
      last = create(:scenario)

      expect(last.position).to be > first.position
    end

    it "starts from the first slot when there is nothing else" do
      expect(create(:scenario).position).to eq(1)
    end

    it "keeps a position that the caller has already decided" do
      expect(create(:scenario, position: 42).position).to eq(42)
    end

    it "orders by the arrangement the GM made" do
      tail = create(:scenario, title: "あ", position: 2)
      head = create(:scenario, title: "ま", position: 1)

      expect(described_class.gm_ordered).to eq([ head, tail ])
    end

    it "falls back to the identifier when two rows share a position" do
      older = create(:scenario, position: 1)
      newer = create(:scenario, position: 1)

      expect(described_class.gm_ordered).to eq([ older, newer ])
    end

    # 入れ替えの途中は旧 Pod が position を知らないまま書き込む。
    it "puts a row with no position at the end" do
      placed = create(:scenario, position: 9)
      unplaced = create(:scenario)
      unplaced.update_column(:position, nil)

      expect(described_class.gm_ordered).to eq([ placed, unplaced ])
    end
  end

  describe ".rearrange" do
    it "renumbers the scenarios into the order it is given" do
      first = create(:scenario)
      second = create(:scenario)
      third = create(:scenario)

      described_class.rearrange([ third.id, first.id, second.id ])

      expect(described_class.gm_ordered).to eq([ third, first, second ])
    end

    it "ignores an identifier that belongs to nothing" do
      scenario = create(:scenario)

      described_class.rearrange([ 0, scenario.id ])

      expect(scenario.reload.position).to eq(2)
    end

    it "leaves out a scenario the caller did not mention" do
      listed = create(:scenario)
      absent = create(:scenario, position: 50)

      described_class.rearrange([ listed.id ])

      expect(absent.reload.position).to eq(50)
    end

    it "keeps the last slot a duplicated identifier was given" do
      first = create(:scenario)
      second = create(:scenario)

      described_class.rearrange([ first.id, second.id, first.id ])

      expect(first.reload.position).to eq(3)
    end
  end

  describe "#move" do
    it "swaps with the row above" do
      top = create(:scenario, title: "うえ")
      bottom = create(:scenario, title: "した")

      bottom.move("up")

      expect(described_class.gm_ordered.pluck(:title)).to eq([ "した", "うえ" ])
    end

    it "swaps with the row below" do
      top = create(:scenario, title: "うえ")
      create(:scenario, title: "した")

      top.move("down")

      expect(described_class.gm_ordered.pluck(:title)).to eq([ "した", "うえ" ])
    end

    it "does nothing at the top" do
      top = create(:scenario, title: "うえ")
      create(:scenario, title: "した")

      top.move("up")

      expect(described_class.gm_ordered.pluck(:title)).to eq([ "うえ", "した" ])
    end

    it "does nothing at the bottom" do
      create(:scenario, title: "うえ")
      bottom = create(:scenario, title: "した")

      bottom.move("down")

      expect(described_class.gm_ordered.pluck(:title)).to eq([ "うえ", "した" ])
    end

    it "ignores a direction it does not know" do
      top = create(:scenario, title: "うえ")
      create(:scenario, title: "した")

      top.move("sideways")

      expect(described_class.gm_ordered.pluck(:title)).to eq([ "うえ", "した" ])
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
    it "requires a minimum, because the list filters on it" do
      expect(build(:scenario, player_count_min: nil)).not_to be_valid
    end

    it "leaves the maximum blank for 「制限なし」" do
      expect(build(:scenario, player_count_min: 1, player_count_max: nil)).to be_valid
    end

    it "takes the same value on both ends for a fixed count" do
      expect(build(:scenario, player_count_min: 3, player_count_max: 3)).to be_valid
    end

    it "rejects a maximum below the minimum" do
      expect(build(:scenario, player_count_min: 3, player_count_max: 2)).not_to be_valid
    end

    it "rejects a table with nobody at it" do
      expect(build(:scenario, player_count_min: 0)).not_to be_valid
    end
  end

  describe "duration" do
    it "holds half hours so that 「30分〜1時間」 fits" do
      scenario = build(:scenario, duration_min_hours: 0.5, duration_max_hours: 1)

      expect(scenario).to be_valid
    end

    it "leaves both ends blank when nobody has timed it" do
      expect(build(:scenario, duration_min_hours: nil, duration_max_hours: nil)).to be_valid
    end

    it "rejects a maximum below the minimum" do
      expect(build(:scenario, duration_min_hours: 2, duration_max_hours: 1)).not_to be_valid
    end

    it "rejects a step finer than half an hour" do
      expect(build(:scenario, duration_min_hours: 1.2)).not_to be_valid
    end

    it "rejects a duration of zero" do
      expect(build(:scenario, duration_min_hours: 0)).not_to be_valid
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
