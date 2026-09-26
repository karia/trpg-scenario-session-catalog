class AddGoogleCredentialsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :google_refresh_token, :text
    add_column :users, :google_scopes, :text
  end
end
