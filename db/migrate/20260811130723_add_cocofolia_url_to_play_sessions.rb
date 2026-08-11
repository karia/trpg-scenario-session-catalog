class AddCocofoliaUrlToPlaySessions < ActiveRecord::Migration[8.1]
  def change
    add_column :play_sessions, :cocofolia_url, :string
  end
end
