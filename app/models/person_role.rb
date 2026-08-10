class PersonRole < ApplicationRecord
  # プレイヤーは全員が持つため保存しない。Person#player? が常に真を返す。
  ROLES = { admin: 0, gm: 1 }.freeze

  belongs_to :person

  enum :name, ROLES, validate: true

  validates :name, uniqueness: { scope: :person_id }
end
