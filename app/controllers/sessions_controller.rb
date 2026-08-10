class SessionsController < ApplicationController
  skip_after_action :verify_authorized

  def create
    user = User.from_google(request.env.fetch("omniauth.auth"))
    reset_session
    session[:user_id] = user.id

    redirect_to root_path, notice: sign_in_notice(user)
  rescue KeyError, ActiveRecord::ActiveRecordError
    failure
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    redirect_to root_path, alert: "ログインできませんでした"
  end

  private
    def sign_in_notice(user)
      return "ログインしました" if user.linked?

      "ログインしました。管理者がメンバー登録するまで、閲覧できるのは公開ページだけです"
    end
end
