class CreatePlaySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :play_sessions do |t|
      t.references :scenario, null: false, foreign_key: true

      # 予定の段階では日付だけ決まっていて時刻が未定のことがあるため、列を分ける。
      t.date :played_on
      t.time :started_at

      # 日付からは導出しない。過去日付の予定が中止のまま残ることがある。
      t.integer :status, null: false, default: 0

      t.string :recording_url
      t.text :note

      t.timestamps
    end
    add_index :play_sessions, :played_on

    create_table :participations do |t|
      t.references :play_session, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.integer :role, null: false

      # GM とサブキーパーは持たないことがある。
      t.string :character_name
      t.string :character_sheet_url

      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :participations, [ :play_session_id, :person_id ], unique: true
  end
end
