class ScenarioPolicy < ApplicationPolicy
  def index? = true
  def show? = true

  # 管理画面は公開側の index? とは別の判断。編集者だけが入る。
  def manage? = editor?

  # シナリオとセッションは GM も編集できる。
  def create? = editor?
  def update? = editor?
  def destroy? = editor?

  # 準備情報は Phase 4 のネタバレ防止ボタンが入るまで誰にも見せない。
  def show_preparation_note? = false

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
