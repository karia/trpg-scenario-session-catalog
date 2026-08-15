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
      @user.assign_attributes(user_params)

      @lost_roles = roles_lost_by_relinking
      return render :edit, status: :unprocessable_content if @lost_roles.any?

      if @user.save
        redirect_to manage_user_path(@user), notice: "紐づけを更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      # 同じ人物の別 provider を外しても、いま使っているアカウントの権限は変わらない。
      def roles_lost_by_relinking
        return [] unless @user.id == current_user&.id

        roles_lost_by(Person.find_by(id: @user.person_id)&.roles)
      end

      def set_user
        @user = policy_scope(User).includes(:person).find(params[:id])
      end

      def user_params
        params.expect(user: [ :person_id ])
      end
  end
end
