class PersonPolicy < ApplicationPolicy
  # Person とグループの管理は管理者だけ。GM には開かない。
  def index? = admin?
  def show? = person.present?
  def create? = admin?
  def update? = admin?
  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person&.admin? ? scope.all : scope.none
    end
  end
end
