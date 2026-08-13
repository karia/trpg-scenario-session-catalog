class MastersController < ApplicationController
  before_action :set_record, only: %i[show edit update destroy]

  def index
    authorize model_class
    @records = policy_scope(model_class)
    render "manage/#{model_class.model_name.route_key}/index"
  end

  def show
    authorize @record
    render "manage/masters/show"
  end

  def new
    @record = authorize model_class.new
    render "manage/masters/new"
  end

  def edit
    authorize @record
    render "manage/masters/edit"
  end

  def create
    @record = authorize model_class.new(record_params)
    return redirect_to(polymorphic_path(@record), notice: "#{@record.name} を登録しました") if @record.save

    render "manage/masters/new", status: :unprocessable_content
  end

  def update
    authorize @record
    return redirect_to(polymorphic_path(@record), notice: "#{@record.name} を更新しました") if @record.update(record_params)

    render "manage/masters/edit", status: :unprocessable_content
  end

  def destroy
    authorize @record
    @record.destroy!
    redirect_to polymorphic_path(model_class), notice: "削除しました"
  end

  private
    def set_record = @record = model_class.find(params[:id])

    def record_params
      params.expect(model_class.model_name.param_key.to_sym => [ :name, :game_master_label, :display_alias_key,
        { aliases_attributes: [ [ :id, :name, :visible, :position, :selection_key, :_destroy ] ] } ])
    end
end
