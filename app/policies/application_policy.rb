# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :person, :record

  def initialize(person, record)
    @person = person
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  # 削除の導線を出すかどうか。destroy? より広い相手に true を返すと、
  # 押せない理由が読める無効なボタンとして出る。
  def offer_destroy? = destroy?

  private
    def admin? = person&.admin?
    def gm? = person&.gm?
    def editor? = admin? || gm?

  class Scope
    def initialize(person, scope)
      @person = person
      @scope = scope
    end

    # 定義漏れが情報漏えいにならないよう、Pundit 既定の例外ではなく空集合を返す。
    def resolve
      scope.none
    end

    private
      attr_reader :person, :scope
  end
end
