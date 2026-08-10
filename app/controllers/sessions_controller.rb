class SessionsController < ApplicationController
  skip_after_action :verify_authorized

  def create
    user = User.from_google(request.env.fetch("omniauth.auth"))
    reset_session
    session[:user_id] = user.id

    redirect_to after_sign_in_path(user)
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    redirect_to root_path, alert: "ログインできませんでした"
  end

  private
    def after_sign_in_path(user)
      return root_path if user.linked?

      root_path
    end
end
