class GeneralizeUserIdentities < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string, null: false, default: "google_oauth2"
    add_column :users, :uid, :string
    add_column :users, :name, :string

    reversible do |direction|
      direction.up { execute "UPDATE users SET uid = google_uid" }
    end

    change_column_null :users, :google_uid, true
    remove_index :users, :person_id, unique: true
    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, [ :person_id, :provider ], unique: true
  end
end
