class Person < ApplicationRecord
  has_one_attached :icon do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 160, 160 ], format: :webp, saver: { quality: 80 }
  end

  has_one :user, dependent: :nullify
  has_many :person_roles, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  validates :display_name, presence: true
  validate :keeps_at_least_one_admin

  default_scope { order(:display_name) }

  # Phase 3 のセッション可視性がこの述語を使う。本人を含めるかは呼び出し側で決められるよう別に分ける。
  scope :sharing_a_group_with, ->(person) {
    return none if person.blank?

    where(id: GroupMembership.where(group_id: GroupMembership.where(person_id: person.id).select(:group_id))
      .select(:person_id)).where.not(id: person.id)
  }

  PersonRole::ROLES.each_key do |role|
    define_method(:"#{role}?") { person_roles.any? { |r| r.name == role.to_s } }
  end

  def roles = person_roles.map(&:name)

  def self.admins = joins(:person_roles).where(person_roles: { name: PersonRole.names[:admin] })

  # has_many への代入は永続レコードだと即座に DB へ反映される。検証で見るため代入前の状態を残す。
  def roles=(names)
    @roles_before_assignment = roles if persisted? && !defined?(@roles_before_assignment)
    self.person_roles = Array(names).compact_blank.uniq.map { |name| PersonRole.new(name:) }
  end

  private
    # 全員が管理者でなくなると、rake タスク以外に復旧手段が無くなる。
    def keeps_at_least_one_admin
      return unless defined?(@roles_before_assignment)
      return unless @roles_before_assignment.include?("admin")
      return if roles.include?("admin")
      return if self.class.admins.where.not(id: id).exists?

      errors.add(:base, "管理者が 0 人になる変更はできません")
    end
end
