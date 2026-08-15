class AddDiscordGuildIdToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :discord_guild_id, :string
    add_index :groups, :discord_guild_id, unique: true
  end
end
