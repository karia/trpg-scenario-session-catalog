class Person < ApplicationRecord
  has_one_attached :icon do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 160, 160 ], format: :webp, saver: { quality: 80 }
  end

  has_one :user, dependent: :nullify
  has_many :person_roles, dependent: :destroy
  has_many :person_aliases, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :person
  has_many :favorites, dependent: :destroy
  has_many :favorite_scenarios, through: :favorites, source: :scenario
  has_many :spoiler_reveals, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  validates :display_name, presence: true
  validates :icon,
    content_type: { in: [ :png, :jpeg, :webp ], spoofing_protection: true },
    size: { less_than: 5.megabytes },
    if: -> { attachment_changes.key?("icon") }
  validate :keeps_at_least_one_admin
  validate :roles_are_known

  default_scope { order(:display_name) }

  PersonRole::ROLES.each_key do |role|
    define_method(:"#{role}?") { person_roles.any? { |r| r.name == role.to_s } }
  end

  # Person であることがそのままプレイヤーであることを表す。付け外しはできない。
  def player? = true

  # 既存行の名前を空にしたときは無視せず検証に落とす。新規の空行だけ捨てる。
  accepts_nested_attributes_for :person_aliases, allow_destroy: true,
    reject_if: ->(attrs) { attrs["id"].blank? && attrs["name"].blank? }

  # 未知の値が入った行は名前を引けない。表示側でロケール全体を出さないよう落とす。
  def roles = person_roles.map(&:name).compact

  def revealed?(scenario) = spoiler_reveals.exists?(scenario_id: scenario.id)

  def favourite?(scenario) = favorites.exists?(scenario_id: scenario.id)

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
