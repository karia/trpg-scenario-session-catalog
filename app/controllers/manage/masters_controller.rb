module Manage
  class MastersController < BaseController
    before_action :set_record, only: %i[show edit update destroy]

    def index
      authorize model_class
      @records = policy_scope(model_class)
      @record = model_class.new
    end

    def show = authorize(@record)
    def edit = authorize(@record)

    def create
      @record = authorize model_class.new(record_params)
      return redirect_to(url_for(action: :show, id: @record), notice: "#{@record.name} を登録しました") if @record.save
      @records = policy_scope(model_class)
      render :index, status: :unprocessable_content
    end

    def update
      authorize @record
      return redirect_to(url_for(action: :show, id: @record), notice: "#{@record.name} を更新しました") if @record.update(record_params)
      render :edit, status: :unprocessable_content
    end

    def destroy
      authorize @record
      @record.destroy!
      redirect_to url_for(action: :index), notice: "削除しました"
    end

    private
      def model_class = raise NotImplementedError
      def set_record = @record = model_class.find(params[:id])
  end
end
