class User < ApplicationRecord
  PROVIDERS = {
    "google_oauth2" => "Google",
    "discord" => "Discord"
  }.freeze

  belongs_to :person, optional: true

  validates :provider, inclusion: { in: PROVIDERS.keys }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :person_id, uniqueness: { scope: :provider }, allow_nil: true
  before_validation :copy_legacy_google_uid

  # 初回は Person 未紐づけで作る。紐づけは管理者が管理画面で行う。
  def self.from_google(auth)
    from_omniauth(auth)
  end

  def self.from_omniauth(auth)
    provider = auth.provider.to_s
    raise ArgumentError, "unsupported provider" unless PROVIDERS.key?(provider)

    uid = auth.uid.to_s
    user = find_by(provider:, uid:)
    user ||= find_by(google_uid: uid) if provider == "google_oauth2"
    user ||= new(provider:, uid:)
    user.provider = provider
    user.uid = uid
    user.google_uid = user.uid if provider == "google_oauth2"
    user.email = auth.info&.email
    user.name = auth.info&.name
    user.save!
    user
  end

  def linked? = person.present?
  def provider_name = PROVIDERS.fetch(provider)

  def join_discord_groups!(guild_ids)
    raise ArgumentError, "not a Discord account" unless provider == "discord"

    groups = Group.where(discord_guild_id: guild_ids).to_a
    return if groups.empty?

    with_lock do
      self.person ||= Person.create!(display_name: name.presence || "Discordユーザー")
      save! if person_id_changed?
      groups.each { |group| person.group_memberships.find_or_create_by!(group:) }
    end
  end

  private
    def copy_legacy_google_uid
      self.uid ||= google_uid if provider == "google_oauth2"
    end
end
