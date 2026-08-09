class CreateScenarios < ActiveRecord::Migration[8.1]
  def change
    create_table :scenarios do |t|
      t.string :title, null: false
      t.text :synopsis
      t.text :preparation_note
      t.text :recommendation_note

      # 星の数。「回したことない」と未評価はどちらも NULL になるため gm_experienced で区別する。
      t.integer :recommendation
      t.boolean :gm_experienced, null: false, default: true

      t.string :character_restriction
      t.integer :character_sheet_deadline

      t.integer :player_count_min
      t.integer :player_count_max
      t.string :player_count_note

      # 「30分～60分」があるため分で持つ。
      t.integer :duration_min_minutes
      t.integer :duration_max_minutes

      t.timestamps
    end

    add_index :scenarios, :title
  end
end
