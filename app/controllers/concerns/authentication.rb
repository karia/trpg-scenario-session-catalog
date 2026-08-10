module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :current_person, :signed_in?
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  # Person に紐づいていないユーザーは nil を返す。ログイン必須エリアはこれで閉じる。
  def current_person
    current_user&.person
  end

  def signed_in? = current_user.present?
end
