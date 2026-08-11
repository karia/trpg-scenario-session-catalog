class UserPolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin?
  def update? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person&.admin? ? scope.all : scope.none
    end
  end
end
