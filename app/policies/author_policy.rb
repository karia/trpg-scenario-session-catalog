class AuthorPolicy < ApplicationPolicy
  def index? = editor?
  def create? = editor?
  def update? = editor?
  def destroy? = editor?
end
