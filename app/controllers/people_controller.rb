class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update destroy]

  def index
    authorize Person
    @people = policy_scope(Person).includes(:aliases, :groups, :person_roles, :user).with_attached_icon
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

  def new
    @person = authorize Person.new, :create?
  end

  def create
    @person = authorize Person.new(admin_person_params), :create?
    return redirect_to(@person, notice: "#{@person.display_name} を登録しました") if @person.save
    render :new, status: :unprocessable_content
  end

  def destroy
    authorize @person, :destroy?
    @person.destroy!
    redirect_to people_path, notice: "削除しました"
  end

  private
    def set_person
      @person = policy_scope(Person).find(params[:id])
    end

    # グループ所属はここでは受け取らない。管理画面（管理者のみ）で扱う。
    def person_params
      permitted = [ :display_name, :display_alias_key, :x_account, :icon,
        { aliases_attributes: [ [ :id, :name, :context, :visible, :position, :selection_key, :_destroy ] ],
          person_aliases_attributes: [ [ :id, :name, :context, :visible, :position, :_destroy ] ] } ]
      permitted << { roles: [], group_ids: [] } if policy(@person).manage?
      params.expect(person: permitted)
    end

    def admin_person_params
      params.expect(person: [ :display_name, :x_account, :icon, { roles: [], group_ids: [] } ])
    end
end
