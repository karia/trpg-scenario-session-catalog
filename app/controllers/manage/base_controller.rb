module Manage
  # 管理者専用エリア。存在を伏せるため権限が無い場合は 404 を返す。
  class BaseController < ApplicationController
    layout "manage"

    before_action :require_admin

    private
      def require_admin
        raise Pundit::NotAuthorizedError unless current_person&.admin?
      end
  end
end
