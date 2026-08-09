class ScenarioPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # 準備情報は Phase 4 のネタバレ防止ボタンが入るまで誰にも見せない。
  def show_preparation_note?
    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
