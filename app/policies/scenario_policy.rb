class ScenarioPolicy < ApplicationPolicy
  def index? = true
  def show? = true

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
