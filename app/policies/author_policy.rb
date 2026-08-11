class AuthorPolicy < ApplicationPolicy
  def index? = editor?
  def show? = editor?
  def create? = editor?
  def update? = editor?
  def destroy? = editor?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person&.admin? || person&.gm? ? scope.all : scope.none
    end
  end
end
