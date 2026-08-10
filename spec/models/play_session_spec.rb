require "rails_helper"

RSpec.describe PlaySession do
  it "belongs to a scenario" do
    expect(build(:play_session, scenario: nil)).not_to be_valid
  end

  describe "schedule" do
    it "allows a date with no time, for a session whose start is not fixed yet" do
      expect(build(:play_session, played_on: Date.new(2026, 9, 1), started_at: nil)).to be_valid
    end

    it "allows neither, for a session with no date at all" do
      expect(build(:play_session, played_on: nil, started_at: nil)).to be_valid
    end
  end

  describe "status" do
    it "defaults to scheduled" do
      expect(described_class.new.status).to eq("scheduled")
    end

    it "covers scheduled, played and cancelled" do
      expect(described_class.statuses.keys).to match_array(%w[scheduled played cancelled])
    end

    it "is not derived from the date, so a past date can still be cancelled" do
      session = build(:play_session, played_on: 1.year.ago.to_date, status: :cancelled)

      expect(session).to be_valid
      expect(session).to be_cancelled
    end
  end

  it "rejects a recording URL that is not an http URL" do
    expect(build(:play_session, recording_url: "javascript:alert(1)")).not_to be_valid
  end

  describe "ordering" do
    it "puts undated sessions last rather than letting the database decide" do
      undated = create(:play_session, played_on: nil)
      older = create(:play_session, played_on: Date.new(2026, 1, 1))
      newer = create(:play_session, played_on: Date.new(2026, 6, 1))

      expect(described_class.newest_first.to_a).to eq([ newer, older, undated ])
    end
  end

  describe "participants" do
    it "records a role for each person" do
      session = create(:play_session)
      gm = create(:person)
      player = create(:person)
      session.participations.create!(person: gm, role: :gm)
      session.participations.create!(person: player, role: :player, character_name: "探索者A")

      expect(session.participations.map(&:role)).to contain_exactly("gm", "player")
    end

    it "does not let the same person join twice" do
      session = create(:play_session)
      person = create(:person)
      session.participations.create!(person:, role: :gm)

      expect(session.participations.build(person:, role: :player)).not_to be_valid
    end

    it "destroys its participations when destroyed" do
      session = create(:play_session)
      session.participations.create!(person: create(:person), role: :gm)

      expect { session.destroy }.to change(Participation, :count).by(-1)
    end
  end
end
