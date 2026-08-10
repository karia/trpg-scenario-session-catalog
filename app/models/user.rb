class User < ApplicationRecord
  belongs_to :person, optional: true

  validates :google_uid, presence: true, uniqueness: true
  validates :person_id, uniqueness: true, allow_nil: true

  # 初回は Person 未紐づけで作る。紐づけは管理者が管理画面で行う。
  def self.from_google(auth)
    user = find_or_initialize_by(google_uid: auth.uid.to_s)
    user.email = auth.info&.email
    user.save!
    user
  end

  def linked? = person.present?
end
