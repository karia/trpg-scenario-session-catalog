class ScenarioPolicy < ApplicationPolicy
  def index? = true
  def show? = true

  # 管理画面は公開側の index? とは別の判断。編集者だけが入る。
  def manage? = editor?

  # シナリオとセッションは GM も編集できる。
  def create? = editor?
  def update? = editor?
  def destroy? = editor?

  # 並び順は公開側の既定の見え方を決めるため、編集と同じ権限で守る。
  def reorder? = editor?

  # お気に入りとネタバレ防止ボタンは Person に紐づくため、紐づいた人だけが押せる。
  def favourite? = person.present?
  def reveal_preparation_note? = person.present?

  # 押した記録があるときだけ本文を返す。CSS では隠さない。
  def show_preparation_note? = person.present? && person.revealed?(record)

  # GM の私見であり、公開エリアの一部ではあっても外部の閲覧者には見せない。
  def show_recommendation_note? = person.present?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
