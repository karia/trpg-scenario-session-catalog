class AddAliases < ActiveRecord::Migration[8.1]
  def change
    add_column :person_aliases, :visible, :boolean, null: false, default: true

    create_table :game_system_aliases do |t|
      t.references :game_system, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :visible, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :author_aliases do |t|
      t.references :author, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :visible, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
