class PlaySessionPolicy < ApplicationPolicy
  def index? = person.present?
  def show? = Scope.new(person, PlaySession).resolve.exists?(record.id)

  # シナリオと同じく、編集できるのは管理者と GM。
  # 管理画面は公開側の index? とは別の判断。編集者だけが入る。
  def manage? = editor?

  def create? = editor?
  def update? = editor?
  def destroy? = editor?

  def show_cocofolia_url?
    person.present? && record.participations.any? { |participation| participation.person_id == person.id }
  end

  def update_cocofolia_url? = !!gm?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if person.blank?
      return scope.all if person.admin?

      # 本人が参加している回と、参加者の誰かと同じグループに属する回。
      # 行が膨らまないよう結合ではなく EXISTS で書く。
      mine = Participation.where("participations.play_session_id = play_sessions.id")

      scope.where(mine.where(person_id: peer_person_ids).arel.exists)
        .or(scope.where(mine.where(person_id: person.id).arel.exists))
    end

    private
      # 同じグループの人の id。本人は所属が無くても参加者として見えるので別に足す。
      def peer_person_ids
        GroupMembership.where(group_id: GroupMembership.where(person_id: person.id).select(:group_id))
          .select(:person_id)
      end
  end
end
