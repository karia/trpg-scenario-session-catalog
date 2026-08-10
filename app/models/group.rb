class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }
end
