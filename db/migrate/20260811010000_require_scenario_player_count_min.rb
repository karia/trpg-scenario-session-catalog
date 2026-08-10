class RequireScenarioPlayerCountMin < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE scenarios SET player_count_min = 1 WHERE player_count_min IS NULL"

    change_column_null :scenarios, :player_count_min, false
    remove_column :scenarios, :player_count_note
  end

  # 補足の本文は戻せない。列だけを戻す。
  def down
    add_column :scenarios, :player_count_note, :string
    change_column_null :scenarios, :player_count_min, true
  end
end
