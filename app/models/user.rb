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

  def sync_discord_groups!(client: nil)
    raise ArgumentError, "not a Discord account" unless provider == "discord"

    groups = Group.where.not(discord_guild_id: nil).to_a
    client ||= DiscordGuildMemberClient.new if groups.any?
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3.seconds
    memberships = groups.index_with do |group|
      Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline && client.member?(group.discord_guild_id, uid)
    rescue DiscordGuildMemberClient::Error => error
      Rails.logger.warn("Discord guild membership check failed: #{error.class}")
      false
    end

    with_lock do
      self.person ||= Person.create!(display_name: name.presence || "Discordユーザー") if memberships.value?(true)
      save! if person_id_changed?
      next unless person

      person.group_memberships.where(discord_managed: true).includes(:group).find_each do |membership|
        membership.destroy! unless memberships.key?(membership.group)
      end
      memberships.each do |group, member|
        membership = person.group_memberships.find_by(group:)
        if member
          person.group_memberships.create!(group:, discord_managed: true) unless membership
        elsif membership&.discord_managed?
          membership.destroy!
        end
      end
    end
  end

  private
    def copy_legacy_google_uid
      self.uid ||= google_uid if provider == "google_oauth2"
    end
end
