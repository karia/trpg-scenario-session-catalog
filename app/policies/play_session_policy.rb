class PlaySessionPolicy < ApplicationPolicy
  def index? = person.present?
  def show? = Scope.new(person, PlaySession).resolve.exists?(record.id)

  # シナリオと同じく、編集できるのは管理者と GM。
  def create? = editor?
  def update? = editor?
  def destroy? = editor?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if person.blank?
      return scope.all if person.admin?

      # 本人が参加している回と、参加者の誰かと同じグループに属する回。
      # 行が膨らまないよう結合ではなく EXISTS で書く。
      scope.where(
        Participation.where("participations.play_session_id = play_sessions.id")
          .where(person_id: visible_person_ids).arel.exists
      )
    end

    private
      def visible_person_ids
        peers = GroupMembership.where(group_id: GroupMembership.where(person_id: person.id).select(:group_id))
          .select(:person_id)

        Person.where(id: peers).or(Person.where(id: person.id)).select(:id)
      end
  end
end
