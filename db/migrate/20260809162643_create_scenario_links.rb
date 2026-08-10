class CreateScenarioLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_game_systems do |t|
      t.references :scenario, null: false, foreign_key: true
      t.references :game_system, null: false, foreign_key: true
      t.timestamps
    end
    add_index :scenario_game_systems, [ :scenario_id, :game_system_id ], unique: true

    create_table :scenario_authors do |t|
      t.references :scenario, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true
      t.timestamps
    end
    add_index :scenario_authors, [ :scenario_id, :author_id ], unique: true

    # url は NULL 可。販売サイトの列に URL でない購入方法の説明が入る行がある。
    create_table :purchase_links do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :label, null: false
      t.string :url
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :stream_links do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :label
      t.string :url, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
