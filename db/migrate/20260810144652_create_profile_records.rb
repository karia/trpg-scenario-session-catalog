class CreateProfileRecords < ActiveRecord::Migration[8.1]
  def change
    # Discord のサーバごとに名前を変えている場合の対応付け。表示名の代わりではない。
    create_table :person_aliases do |t|
      t.references :person, null: false, foreign_key: true
      t.string :name, null: false
      t.string :context
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :favorites do |t|
      t.references :person, null: false, foreign_key: true
      t.references :scenario, null: false, foreign_key: true
      t.timestamps
    end
    add_index :favorites, [ :person_id, :scenario_id ], unique: true

    # ネタバレ防止ボタンを押した記録。端末ではなく Person に紐づける。
    create_table :spoiler_reveals do |t|
      t.references :person, null: false, foreign_key: true
      t.references :scenario, null: false, foreign_key: true
      t.timestamps
    end
    add_index :spoiler_reveals, [ :person_id, :scenario_id ], unique: true
  end
end
