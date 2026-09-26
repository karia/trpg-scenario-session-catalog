class GoogleAccountPolicy < ApplicationPolicy
  def link? = person.present? && person == record
  def unlink? = person.present? && (person == record || person.admin?)
end
