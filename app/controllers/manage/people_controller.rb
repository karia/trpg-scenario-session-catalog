module Manage
  class PeopleController < BaseController
    before_action :set_person, only: %i[edit update destroy]

    def index
      authorize Person
      @people = policy_scope(Person).includes(:person_roles, :groups, :user)
      @person = Person.new
    end

    def new
      @person = authorize Person.new
    end

    def edit
      authorize @person
    end

    def create
      @person = authorize Person.new(person_params)

      if @person.save
        redirect_to manage_people_path, notice: "#{@person.display_name} を登録しました"
      else
        @people = policy_scope(Person)
        render :index, status: :unprocessable_content
      end
    end

    def update
      authorize @person

      if @person.update(person_params)
        redirect_to manage_people_path, notice: "#{@person.display_name} を更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @person
      @person.destroy!
      redirect_to manage_people_path, notice: "削除しました"
    end

    private
      def set_person
        @person = Person.find(params[:id])
      end

      def person_params
        params.expect(person: [ :display_name, :x_account, :icon, { roles: [], group_ids: [] } ])
      end
  end
end
