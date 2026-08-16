class PersonPolicy < ApplicationPolicy
  # プロフィールはログイン済みのメンバー同士なら見える。
  def index? = person.present?
  def show? = person.present?

  # 本人と管理者が編集できる。グループ所属だけは管理画面（管理者のみ）で扱う。
  def update? = admin? || person == record

  # Person の追加と削除、グループ所属の変更は管理者だけ。GM には開かない。
  def manage? = admin?
  def create? = admin?

  # 自分を消せる相手がいないため、管理者が 0 人になる経路も生まれない。
  def destroy? = admin? && record != person
  def offer_destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person.present? ? scope.all : scope.none
    end
  end
end
