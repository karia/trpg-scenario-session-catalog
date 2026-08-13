class AddGameMasterLabelToGameSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :game_systems, :game_master_label, :string
  end
end
