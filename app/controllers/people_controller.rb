class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update]

  def index
    authorize Person
    @people = policy_scope(Person).includes(:person_aliases, :groups).with_attached_icon
  end

  def show
    authorize @person
  end

  def edit
    authorize @person, :update?
  end

  def update
    authorize @person, :update?

    if @person.update(person_params)
      redirect_to person_path(@person), notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_person
      @person = policy_scope(Person).find(params[:id])
    end

    # グループ所属はここでは受け取らない。管理画面（管理者のみ）で扱う。
    def person_params
      params.expect(person: [ :display_name, :x_account, :icon,
        { person_aliases_attributes: [ [ :id, :name, :context, :position, :_destroy ] ] } ])
    end
end
