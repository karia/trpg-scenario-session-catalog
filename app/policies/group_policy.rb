class GroupPolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin?
  def create? = admin?
  def update? = admin?
  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person&.admin? ? scope.all : scope.none
    end
  end
end
