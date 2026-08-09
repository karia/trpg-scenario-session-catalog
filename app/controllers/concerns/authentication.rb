module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  # Phase 2 で Google 認証に差し替える。それまで全リクエストが未ログイン扱いになる。
  def current_user
    nil
  end
end
