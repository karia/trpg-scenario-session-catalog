class AddDiscordManagedToGroupMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :group_memberships, :discord_managed, :boolean, default: false, null: false
  end
end
