class Participation < ApplicationRecord
  enum :role, { gm: 0, player: 1, sub_gm: 2 }, validate: true

  belongs_to :play_session
  belongs_to :person

  validates :person_id, uniqueness: { scope: :play_session_id }
  validates :character_sheet_url, http_url: true
end
