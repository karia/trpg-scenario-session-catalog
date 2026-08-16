class UserPolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin?
  def update? = admin?

  # 自分のログイン手段を消すと、その場で締め出される。
  def destroy? = admin? && record.person_id != person.id
  def offer_destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person&.admin? ? scope.all : scope.none
    end
  end
end
