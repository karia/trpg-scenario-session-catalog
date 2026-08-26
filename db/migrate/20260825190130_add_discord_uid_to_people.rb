class AddDiscordUidToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :discord_uid, :string
    add_index :people, :discord_uid, unique: true
  end
end
