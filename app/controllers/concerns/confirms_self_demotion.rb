module ConfirmsSelfDemotion
  extend ActiveSupport::Concern

  private
    # 操作後に current_person が持つ role を渡すと、この操作で失う role を返す。
    # ログイン中の自分だけを見る。同じ人物の別 provider や他人への操作では呼ばない。
    def roles_lost_by(after_roles)
      return [] if current_person.nil?

      lost = current_person.roles - Array(after_roles).compact_blank.map(&:to_s)
      # 警告を出した後にフォームを書き換えられても、了解済みの role より先へは進ませない。
      lost - params[:confirm_self_demotion].to_s.split(",")
    end
end
