class AddPositionToScenarios < ActiveRecord::Migration[8.0]
  def up
    add_column :scenarios, :position, :integer
    execute <<~SQL.squish
      UPDATE scenarios SET position = ranked.rank
      FROM (
        SELECT id, ROW_NUMBER() OVER (ORDER BY recommendation DESC NULLS LAST, title) AS rank
        FROM scenarios
      ) AS ranked
      WHERE scenarios.id = ranked.id
    SQL
    change_column_null :scenarios, :position, false
    add_index :scenarios, :position
  end

  def down
    remove_column :scenarios, :position
  end
end
