require "rails_helper"

RSpec.describe PlaySession do
  it "belongs to a scenario" do
    expect(build(:play_session, scenario: nil)).not_to be_valid
  end

  describe "schedules" do
    it "keeps multiple starts in chronological order" do
      session = create(:play_session)
      later = create(:session_schedule, play_session: session, started_at: Time.zone.local(2026, 5, 3, 20))
      earlier = create(:session_schedule, play_session: session, started_at: Time.zone.local(2026, 5, 1, 20))

      expect(session.session_schedules.reload).to eq([ earlier, later ])
    end

    it "destroys schedules and their recording links with the session" do
      schedule = create(:session_schedule)
      create(:recording_link, session_schedule: schedule)

      expect { schedule.play_session.destroy! }
        .to change(SessionSchedule, :count).by(-1)
        .and change(RecordingLink, :count).by(-1)
    end
  end

  describe "status" do
    it "is scheduled before the first start" do
      session = create(:play_session)
      create(:session_schedule, play_session: session, started_at: Time.zone.local(2026, 5, 1, 20))

      expect(session.derived_status(Time.zone.local(2026, 5, 1, 19, 59))).to eq(:scheduled)
    end

    it "is in progress from the first start until the last start" do
      session = create(:play_session)
      create(:session_schedule, play_session: session, started_at: Time.zone.local(2026, 5, 1, 20))
      create(:session_schedule, play_session: session, started_at: Time.zone.local(2026, 5, 3, 20))

      expect(session.derived_status(Time.zone.local(2026, 5, 2, 20))).to eq(:in_progress)
    end

    it "is completed from the last start" do
      session = create(:play_session)
      create(:session_schedule, play_session: session, started_at: Time.zone.local(2026, 5, 1, 20))

      expect(session.derived_status(Time.zone.local(2026, 5, 1, 20))).to eq(:completed)
    end

    it "treats an undated session as scheduled" do
      expect(create(:play_session).derived_status).to eq(:scheduled)
    end
  end

  it "rejects a Cocofolia URL that is not an http URL" do
    expect(build(:play_session, cocofolia_url: "javascript:alert(1)")).not_to be_valid
  end

  describe "ordering" do
    it "orders by the first start and puts undated sessions last" do
      undated = create(:play_session)
      older = create(:play_session)
      newer = create(:play_session)
      create(:session_schedule, play_session: older, started_at: Time.zone.local(2026, 1, 1, 20))
      create(:session_schedule, play_session: newer, started_at: Time.zone.local(2026, 6, 1, 20))

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
