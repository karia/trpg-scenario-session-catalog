class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships

  validates :name, presence: true, uniqueness: true
  validates :discord_guild_id, uniqueness: true, format: { with: /\A\d{17,20}\z/ }, allow_nil: true
  normalizes :discord_guild_id, with: ->(value) { value.presence }

  def manual_person_ids
    group_memberships.where(discord_managed: false).pluck(:person_id)
  end

  def manual_person_ids=(ids)
    desired_ids = Array(ids).reject(&:blank?).map(&:to_i)
    group_memberships.where(discord_managed: false).where.not(person_id: desired_ids).destroy_all
    desired_ids.each do |person_id|
      membership = group_memberships.find_or_initialize_by(person_id:)
      membership.update!(discord_managed: false)
    end
  end

  default_scope { order(:name) }
end
