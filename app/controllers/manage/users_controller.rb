module Manage
  # Google アカウントと Person の紐づけだけを扱う。ユーザーの作成と削除はしない。
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update]

    def index
      authorize User
      @users = policy_scope(User).includes(:person).order(:created_at)
    end

    def show
      authorize @user
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      if @user.update(user_params)
        redirect_to manage_user_path(@user), notice: "紐づけを更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      def set_user
        @user = policy_scope(User).includes(:person).find(params[:id])
      end

      def user_params
        params.expect(user: [ :person_id ])
      end
  end
end
