class SessionsController < ApplicationController
  skip_after_action :verify_authorized

  def create
    auth = request.env.fetch("omniauth.auth")
    user = User.from_omniauth(auth)
    join_discord_groups(user, auth)
    reset_session
    session[:user_id] = user.id

    redirect_to return_to_url, notice: sign_in_notice(user)
  rescue KeyError, ArgumentError, ActiveRecord::ActiveRecordError
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
    def join_discord_groups(user, auth)
      return unless user.provider == "discord"

      user.join_discord_groups!(DiscordGuildsClient.new.guild_ids(auth.credentials.token))
    rescue DiscordGuildsClient::Error => error
      Rails.logger.warn("Discord guild sync failed: #{error.class}")
    end

    def return_to_url
      url_from(request.env["omniauth.origin"]) || root_path
    end

    def sign_in_notice(user)
      "ログインしました" if user.linked?
    end
end
