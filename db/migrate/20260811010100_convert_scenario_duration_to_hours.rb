class ConvertScenarioDurationToHours < ActiveRecord::Migration[8.1]
  def up
    add_column :scenarios, :duration_min_hours, :decimal, precision: 4, scale: 1
    add_column :scenarios, :duration_max_hours, :decimal, precision: 4, scale: 1

    # 30 分に満たない端数は、下限を切り捨て、上限を切り上げる。目安の幅は縮めない。
    execute <<~SQL.squish
      UPDATE scenarios SET
        duration_min_hours = CASE
          WHEN duration_min_minutes IS NULL THEN NULL
          ELSE GREATEST(FLOOR(duration_min_minutes / 30.0) * 0.5, 0.5)
        END,
        duration_max_hours = CASE
          WHEN duration_max_minutes IS NULL THEN NULL
          ELSE GREATEST(CEIL(duration_max_minutes / 30.0) * 0.5, 0.5)
        END
    SQL

    remove_column :scenarios, :duration_min_minutes
    remove_column :scenarios, :duration_max_minutes
  end

  def down
    add_column :scenarios, :duration_min_minutes, :integer
    add_column :scenarios, :duration_max_minutes, :integer

    execute <<~SQL.squish
      UPDATE scenarios SET
        duration_min_minutes = (duration_min_hours * 60)::integer,
        duration_max_minutes = (duration_max_hours * 60)::integer
    SQL

    remove_column :scenarios, :duration_min_hours
    remove_column :scenarios, :duration_max_hours
  end
end
