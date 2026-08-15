class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships

  validates :name, presence: true, uniqueness: true
  validates :discord_guild_id, uniqueness: true, format: { with: /\A\d{17,20}\z/ }, allow_nil: true
  normalizes :discord_guild_id, with: ->(value) { value.presence }

  default_scope { order(:name) }
end
