class User < ApplicationRecord
  PROVIDERS = {
    "google_oauth2" => "Google",
    "discord" => "Discord"
  }.freeze

  belongs_to :person, optional: true

  validates :provider, inclusion: { in: PROVIDERS.keys }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :person_id, uniqueness: { scope: :provider }, allow_nil: true

  # 初回は Person 未紐づけで作る。紐づけは管理者が管理画面で行う。
  def self.from_google(auth)
    from_omniauth(auth)
  end

  def self.from_omniauth(auth)
    provider = auth.provider.to_s
    raise ArgumentError, "unsupported provider" unless PROVIDERS.key?(provider)

    user = find_or_initialize_by(provider:, uid: auth.uid.to_s)
    user.google_uid = user.uid if provider == "google_oauth2"
    user.email = auth.info&.email
    user.name = auth.info&.name
    user.save!
    user
  end

  def linked? = person.present?
  def provider_name = PROVIDERS.fetch(provider)
end
