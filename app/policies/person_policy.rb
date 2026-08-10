class PersonPolicy < ApplicationPolicy
  # プロフィールはログイン済みのメンバー同士なら見える。
  def index? = person.present?
  def show? = person.present?

  # 本人と管理者が編集できる。グループ所属だけは管理画面（管理者のみ）で扱う。
  def update? = admin? || person == record

  # Person の追加と削除、グループ所属の変更は管理者だけ。GM には開かない。
  def manage? = admin?
  def create? = admin?
  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      person.present? ? scope.all : scope.none
    end
  end
end
