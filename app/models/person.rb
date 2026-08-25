class Person < ApplicationRecord
  DISPLAY_NAME_ATTRIBUTE = :display_name
  has_one_attached :icon do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 160, 160, { sharpen: true } ], format: :webp, saver: { quality: 80 }
  end

  has_many :users, dependent: :nullify
  has_many :person_roles, dependent: :destroy
  has_many :aliases, -> { order(:position, :id) }, class_name: "PersonAlias", dependent: :destroy,
    inverse_of: :person
  alias_method :person_aliases, :aliases
  include HasAliases
  has_many :favorites, dependent: :destroy
  has_many :favorite_scenarios, through: :favorites, source: :scenario
  has_many :spoiler_reveals, dependent: :destroy
  has_many :scenario_statuses, dependent: :destroy
  has_many :owned_scenarios, through: :scenario_statuses, source: :scenario
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  # 参加記録が残る人は消させない。消すとセッションから参加者が抜け落ちる。
  has_many :participations, dependent: :restrict_with_error

  validates :display_name, presence: true
  validates :discord_uid, uniqueness: true, format: { with: /\A\d{17,20}\z/ }, allow_nil: true
  normalizes :discord_uid, with: ->(value) { value.presence }
  validates :icon,
    content_type: { in: [ :png, :jpeg, :webp ], spoofing_protection: true },
    size: { less_than: 5.megabytes },
    if: -> { attachment_changes.key?("icon") }
  validate :keeps_at_least_one_admin
  validate :roles_are_known
  validate :discord_uid_is_available

  default_scope { order(:display_name) }

  PersonRole::ROLES.each_key do |role|
    define_method(:"#{role}?") { person_roles.any? { |r| r.name == role.to_s } }
  end

  # Person であることがそのままプレイヤーであることを表す。付け外しはできない。
  def player? = true

  # 既存行の名前を空にしたときは無視せず検証に落とす。新規の空行だけ捨てる。
  alias_method :person_aliases_attributes=, :aliases_attributes=

  # 未知の値が入った行は名前を引けない。表示側でロケール全体を出さないよう落とす。
  def roles = person_roles.map(&:name).compact

  def revealed?(scenario) = spoiler_reveals.exists?(scenario_id: scenario.id)

  def favourite?(scenario) = favorites.exists?(scenario_id: scenario.id)

  def manual_group_ids
    group_memberships.where(discord_managed: false).pluck(:group_id)
  end

  def manual_group_ids=(ids)
    desired_ids = Array(ids).reject(&:blank?).map(&:to_i)
    if new_record?
      desired_ids.each { |group_id| group_memberships.build(group_id:, discord_managed: false) }
      return
    end

    group_memberships.where(discord_managed: false).where.not(group_id: desired_ids).destroy_all
    desired_ids.each do |group_id|
      membership = group_memberships.find_or_initialize_by(group_id:)
      membership.update!(discord_managed: false)
    end
  end

  def self.admins = joins(:person_roles).where(person_roles: { name: PersonRole.names[:admin] })

  # has_many への代入は永続レコードだと即座に DB へ反映される。検証で見るため代入前の状態を残す。
  # 古いフォームが送ってくる player だけを黙って落とす。それ以外の未知の値は検証エラーにする。
  # 不正な行をそのまま代入すると RecordNotSaved で 500 になるため、ここで取り分ける。
  def roles=(names)
    @roles_before_assignment = roles if persisted? && !defined?(@roles_before_assignment)
    submitted = Array(names).compact_blank.uniq - %w[player]
    @unknown_roles = submitted - PersonRole::ROLES.keys.map(&:to_s)
    self.person_roles = (submitted - @unknown_roles).map { |name| PersonRole.new(name:) }
  end

  private
    def discord_uid_is_available
      return if discord_uid.blank?

      discord_user = User.find_by(provider: "discord", uid: discord_uid)
      return if discord_user.nil? || (id.present? && discord_user.person_id == id)

      errors.add(:discord_uid, "は別のアカウントで使用されています")
    end

    def roles_are_known
      return if @unknown_roles.blank?

      errors.add(:base, "知らない権限です: #{@unknown_roles.join(", ")}")
    end

    # 全員が管理者でなくなると、rake タスク以外に復旧手段が無くなる。
    def keeps_at_least_one_admin
      return unless defined?(@roles_before_assignment)
      return unless @roles_before_assignment.include?("admin")
      return if roles.include?("admin")
      return if self.class.admins.where.not(id: id).exists?

      errors.add(:base, "管理者が 0 人になる変更はできません")
    end
end
