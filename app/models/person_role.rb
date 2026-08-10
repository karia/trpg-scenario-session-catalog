class PersonRole < ApplicationRecord
  ROLES = { admin: 0, gm: 1, player: 2 }.freeze

  belongs_to :person

  enum :name, ROLES, validate: true

  validates :name, uniqueness: { scope: :person_id }
end
