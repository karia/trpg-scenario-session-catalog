class SiteSettingPolicy < ApplicationPolicy
  def show? = admin?
  def update? = admin?
end
