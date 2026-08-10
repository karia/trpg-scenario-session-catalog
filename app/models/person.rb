class Person < ApplicationRecord
  has_one_attached :icon do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 160, 160 ], format: :webp, saver: { quality: 80 }
  end

  has_one :user, dependent: :nullify
  has_many :person_roles, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  validates :display_name, presence: true

  default_scope { order(:display_name) }

  scope :sharing_a_group_with, ->(person) {
    where.not(id: person.id)
      .where(id: GroupMembership.where(group_id: person.group_ids).select(:person_id))
  }

  PersonRole::ROLES.each_key do |role|
    define_method(:"#{role}?") { person_roles.any? { |r| r.name == role.to_s } }
  end

  def roles = person_roles.map(&:name)

  def roles=(names)
    self.person_roles = Array(names).compact_blank.uniq.map { |name| PersonRole.new(name:) }
  end
end
