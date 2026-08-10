module Manage
  # 管理者と GM だけが入れる編集エリア。存在を伏せるため権限が無い場合は 404 を返す。
  class BaseController < ApplicationController
    layout "manage"

    before_action :require_editor

    private
      def require_editor
        raise Pundit::NotAuthorizedError unless current_person&.admin? || current_person&.gm?
      end
  end
end
