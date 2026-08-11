class CreateSessionSchedulesAndRecordingLinks < ActiveRecord::Migration[8.1]
  def up
    create_table :session_schedules do |t|
      t.references :play_session, null: false, foreign_key: true
      t.datetime :started_at
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :session_schedules, [ :play_session_id, :started_at ]

    create_table :recording_links do |t|
      t.references :session_schedule, null: false, foreign_key: true
      t.string :url, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    execute <<~SQL
      INSERT INTO session_schedules (play_session_id, started_at, position, created_at, updated_at)
      SELECT id,
             CASE WHEN played_on IS NULL THEN NULL
                  ELSE played_on + COALESCE(started_at, TIME '00:00') END,
             0, created_at, updated_at
      FROM play_sessions
      WHERE played_on IS NOT NULL OR NULLIF(recording_url, '') IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO recording_links (session_schedule_id, url, position, created_at, updated_at)
      SELECT session_schedules.id, play_sessions.recording_url, 0,
             play_sessions.created_at, play_sessions.updated_at
      FROM play_sessions
      INNER JOIN session_schedules ON session_schedules.play_session_id = play_sessions.id
      WHERE NULLIF(play_sessions.recording_url, '') IS NOT NULL
    SQL
  end

  def down
    drop_table :recording_links
    drop_table :session_schedules
  end
end
