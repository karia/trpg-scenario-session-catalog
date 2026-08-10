class CreatePeopleAndUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :display_name, null: false
      t.string :x_account
      t.timestamps
    end

    # person_id が NULL のユーザーは、ログイン済みだが公開エリアしか見られない通常の状態。
    create_table :users do |t|
      t.string :google_uid, null: false
      t.string :email
      t.references :person, foreign_key: true, index: { unique: true }
      t.timestamps
    end
    add_index :users, :google_uid, unique: true

    create_table :person_roles do |t|
      t.references :person, null: false, foreign_key: true
      t.integer :name, null: false
      t.timestamps
    end
    add_index :person_roles, [ :person_id, :name ], unique: true

    create_table :groups do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :groups, :name, unique: true

    create_table :group_memberships do |t|
      t.references :person, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.timestamps
    end
    add_index :group_memberships, [ :person_id, :group_id ], unique: true
  end
end
