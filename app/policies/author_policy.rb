class AuthorPolicy < ApplicationPolicy
  def index? = person.present?
  def show? = person.present?
  def create? = editor?
  def update? = editor?
  def destroy? = editor?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person.present? ? scope.all : scope.none
    end
  end
end
