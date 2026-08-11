class CreateSessionSchedulesAndRecordingLinks < ActiveRecord::Migration[8.1]
  def up
    create_table :session_schedules do |t|
      t.references :play_session, null: false, foreign_key: true
      t.date :scheduled_on
      t.time :started_at
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :session_schedules, [ :play_session_id, :scheduled_on, :started_at ]

    create_table :recording_links do |t|
      t.references :session_schedule, null: false, foreign_key: true
      t.string :url, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    execute <<~SQL
      CREATE FUNCTION sync_legacy_play_session_schedule() RETURNS trigger AS $$
      DECLARE
        schedule_id bigint;
        recording_id bigint;
      BEGIN
        IF TG_OP = 'INSERT' AND NEW.played_on IS NULL AND NEW.started_at IS NULL
          AND NULLIF(NEW.recording_url, '') IS NULL THEN
          RETURN NEW;
        END IF;

        SELECT id INTO schedule_id FROM session_schedules
        WHERE play_session_id = NEW.id ORDER BY position, id LIMIT 1;

        IF schedule_id IS NULL THEN
          IF NEW.played_on IS NULL AND NEW.started_at IS NULL AND NULLIF(NEW.recording_url, '') IS NULL THEN
            RETURN NEW;
          END IF;

          INSERT INTO session_schedules
            (play_session_id, scheduled_on, started_at, position, created_at, updated_at)
          VALUES (NEW.id, NEW.played_on, NEW.started_at, 0, NEW.created_at, NEW.updated_at)
          RETURNING id INTO schedule_id;
        ELSE
          UPDATE session_schedules
          SET scheduled_on = NEW.played_on, started_at = NEW.started_at, updated_at = NEW.updated_at
          WHERE id = schedule_id;
        END IF;

        SELECT id INTO recording_id FROM recording_links
        WHERE session_schedule_id = schedule_id ORDER BY position, id LIMIT 1;

        IF NULLIF(NEW.recording_url, '') IS NULL THEN
          DELETE FROM recording_links WHERE id = recording_id;
        ELSIF recording_id IS NULL THEN
          INSERT INTO recording_links
            (session_schedule_id, url, position, created_at, updated_at)
          VALUES (schedule_id, NEW.recording_url, 0, NEW.created_at, NEW.updated_at);
        ELSE
          UPDATE recording_links SET url = NEW.recording_url, updated_at = NEW.updated_at
          WHERE id = recording_id;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER sync_legacy_play_session_schedule
      AFTER INSERT OR UPDATE OF played_on, started_at, recording_url ON play_sessions
      FOR EACH ROW EXECUTE FUNCTION sync_legacy_play_session_schedule();
    SQL

    execute <<~SQL
      UPDATE play_sessions SET played_on = played_on
      WHERE played_on IS NOT NULL OR started_at IS NOT NULL OR NULLIF(recording_url, '') IS NOT NULL
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS sync_legacy_play_session_schedule ON play_sessions"
    execute "DROP FUNCTION IF EXISTS sync_legacy_play_session_schedule()"
    drop_table :recording_links
    drop_table :session_schedules
  end
end
