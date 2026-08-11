require "rails_helper"
require Rails.root.join("db/migrate/20260811170106_create_session_schedules_and_recording_links")

RSpec.describe CreateSessionSchedulesAndRecordingLinks do
  self.use_transactional_tests = false

  around do |example|
    verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    migrate(:down)
    example.run
  ensure
    RecordingLink.delete_all if RecordingLink.table_exists?
    SessionSchedule.delete_all if SessionSchedule.table_exists?
    PlaySession.delete_all
    Scenario.delete_all
    ActiveRecord::Migration.verbose = verbose
    ActiveRecord::Base.connection.clear_cache!
  end

  def migrate(direction)
    described_class.new.migrate(direction)
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.connection.clear_cache!
    [ PlaySession, SessionSchedule, RecordingLink ].each(&:reset_column_information)
  end

  def insert_legacy_session(attributes)
    scenario = create(:scenario)
    now = Time.current
    PlaySession.insert_all!([ {
      scenario_id: scenario.id, status: 0, created_at: now, updated_at: now
    }.merge(attributes) ])
    PlaySession.order(:id).last
  end

  it "preserves an existing local date, optional time and recording" do
    session = insert_legacy_session(
      played_on: Date.new(2026, 5, 1), started_at: nil, recording_url: "https://youtu.be/legacy"
    )

    migrate(:up)

    schedule = SessionSchedule.find_by!(play_session_id: session.id)
    expect(schedule).to have_attributes(scheduled_on: Date.new(2026, 5, 1), started_at: nil)
    expect(schedule.recording_links.sole.url).to eq("https://youtu.be/legacy")
  end

  it "syncs writes made by an old pod after the migration" do
    session = insert_legacy_session(played_on: nil, started_at: nil, recording_url: nil)
    migrate(:up)

    PlaySession.where(id: session.id).update_all(
      played_on: Date.new(2026, 5, 3), started_at: "21:00", recording_url: "https://youtu.be/late"
    )

    schedule = SessionSchedule.find_by!(play_session_id: session.id)
    expect(schedule.scheduled_on).to eq(Date.new(2026, 5, 3))
    expect(schedule.started_at.strftime("%H:%M")).to eq("21:00")
    expect(schedule.recording_links.sole.url).to eq("https://youtu.be/late")

    PlaySession.where(id: session.id).update_all(played_on: nil, started_at: nil, recording_url: nil)

    expect(schedule.reload).to have_attributes(scheduled_on: nil, started_at: nil)
    expect(schedule.recording_links).to be_empty
  end
end
