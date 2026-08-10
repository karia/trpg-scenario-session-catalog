module Manage
  # Google アカウントと Person の紐づけだけを扱う。ユーザーの作成と削除はしない。
  class UsersController < BaseController
    def index
      authorize User
      @users = policy_scope(User).includes(:person).order(:created_at)
    end

    def update
      user = authorize User.find(params[:id])

      if user.update(user_params)
        redirect_to manage_users_path, notice: "紐づけを更新しました"
      else
        @users = policy_scope(User).includes(:person).order(:created_at)
        @error_user = user
        render :index, status: :unprocessable_content
      end
    end

    private
      def user_params
        params.expect(user: [ :person_id ])
      end
  end
end
