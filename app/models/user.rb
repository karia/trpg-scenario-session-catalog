class User < ApplicationRecord
  DISCORD_SYNC_DEADLINE = 3.seconds
  PROVIDERS = {
    "google_oauth2" => "Google",
    "discord" => "Discord"
  }.freeze

  belongs_to :person, optional: true

  encrypts :google_refresh_token, :google_scopes

  validates :provider, inclusion: { in: PROVIDERS.keys }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :person_id, uniqueness: { scope: :provider }, allow_nil: true
  before_validation :copy_legacy_google_uid
  before_destroy :revoke_google_access!

  # 初回は Person 未紐づけで作る。紐づけは管理者が管理画面で行う。
  def self.from_google(auth)
    from_omniauth(auth)
  end

  def self.link_google(auth, person)
    raise ArgumentError, "unsupported provider" unless auth.provider.to_s == "google_oauth2"

    token = auth.credentials&.refresh_token.to_s.presence or raise ArgumentError, "missing refresh token"
    scopes = auth.credentials.scope.to_s.split(/[\s,]+/).uniq
    if (scopes - person.google_oauth_scopes).any?
      GoogleTokenRevoker.revoke(token)
      raise ArgumentError, "scope no longer allowed"
    end
    user = find_or_initialize_by(provider: "google_oauth2", uid: auth.uid.to_s)
    raise ArgumentError, "Google account already linked" if user.person && user.person != person

    user.assign_attributes(
      person:, google_uid: auth.uid.to_s, email: auth.info&.email, name: auth.info&.name,
      google_refresh_token: token,
      google_scopes: scopes.join(" ")
    )
    user.save!
    user
  end

  def self.from_omniauth(auth)
    provider = auth.provider.to_s
    raise ArgumentError, "unsupported provider" unless PROVIDERS.key?(provider)

    uid = auth.uid.to_s
    user = find_by(provider:, uid:)
    user ||= find_by(google_uid: uid) if provider == "google_oauth2"
    prelinked_person = Person.find_by(discord_uid: uid) if provider == "discord"
    user ||= new(provider:, uid:)
    user.person ||= prelinked_person
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

  def unlink_google!
    transaction do
      revoke_google_access!
      update!(person: nil)
    end
  end

  def revoke_google_access!
    return unless provider == "google_oauth2" && google_refresh_token.present?

    GoogleTokenRevoker.revoke(google_refresh_token)
    update_columns(google_refresh_token: nil, google_scopes: nil)
  end

  def sync_discord_groups!(client: nil)
    raise ArgumentError, "not a Discord account" unless provider == "discord"

    groups = Group.where.not(discord_guild_id: nil).to_a
    client ||= DiscordGuildMemberClient.new if groups.any?
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + DISCORD_SYNC_DEADLINE
    memberships = groups.index_with do |group|
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Timeout.timeout(remaining) { client.member?(group.discord_guild_id, uid) } if remaining.positive?
    rescue DiscordGuildMemberClient::Error, Timeout::Error => error
      Rails.logger.warn("Discord guild membership check failed: #{error.class}")
      nil
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
        elsif member == false && membership&.discord_managed?
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
