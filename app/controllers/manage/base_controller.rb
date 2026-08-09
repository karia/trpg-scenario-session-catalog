module Manage
  # Phase 2 で Pundit による役割判定に差し替える。それまでの暫定的な保護。
  class BaseController < ApplicationController
    before_action :authenticate_editor
    skip_after_action :verify_authorized

    private
      def authenticate_editor
        username = ENV["MANAGE_USERNAME"]
        password = ENV["MANAGE_PASSWORD"]
        return head :unauthorized if username.blank? || password.blank?

        authenticate_or_request_with_http_basic("Manage") do |given_user, given_password|
          # 不正な Authorization ヘッダでは password が nil になる。to_s で受ける。
          ActiveSupport::SecurityUtils.secure_compare(given_user.to_s, username) &
            ActiveSupport::SecurityUtils.secure_compare(given_password.to_s, password)
        end
      end
  end
end
