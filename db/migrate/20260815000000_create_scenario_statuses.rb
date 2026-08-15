class CreateScenarioStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_statuses do |t|
      t.references :person, null: false, foreign_key: true
      t.references :scenario, null: false, foreign_key: true
      t.boolean :gm_experienced, null: false, default: false
      t.boolean :pl_experienced, null: false, default: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end

    add_index :scenario_statuses, [ :person_id, :scenario_id ], unique: true

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO scenario_statuses
            (person_id, scenario_id, gm_experienced, pl_experienced, read, created_at, updated_at)
          SELECT person_roles.person_id, scenarios.id, scenarios.gm_experienced, FALSE, FALSE,
                 CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
          FROM person_roles CROSS JOIN scenarios
          WHERE person_roles.name = 0
        SQL
      end
    end
  end
end
