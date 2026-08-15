module ConfirmsSelfDemotion
  extend ActiveSupport::Concern

  private
    # 操作後に current_person が持つ role を渡すと、この操作で失う role を返す。
    # ログイン中の自分だけを見る。同じ人物の別 provider や他人への操作では呼ばない。
    def roles_lost_by(after_roles)
      return [] if params[:confirm_self_demotion].present?
      return [] if current_person.nil?

      current_person.roles - Array(after_roles).compact_blank.map(&:to_s)
    end
end
