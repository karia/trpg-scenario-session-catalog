module Manage
  # GameSystem と Author は名前だけの一覧なので、同じ振る舞いを共有する。
  class MastersController < BaseController
    before_action :set_record, only: %i[edit update destroy]

    def index
      authorize model_class
      @records = model_class.all
      @record = model_class.new
    end

    def new
      redirect_to url_for(action: :index)
    end

    def edit
      authorize @record
      @records = model_class.all
      render :index
    end

    def create
      @record = authorize model_class.new(record_params)

      if @record.save
        redirect_to url_for(action: :index), notice: "#{@record.name} を登録しました"
      else
        @records = model_class.all
        render :index, status: :unprocessable_content
      end
    end

    def update
      authorize @record

      if @record.update(record_params)
        redirect_to url_for(action: :index), notice: "#{@record.name} を更新しました"
      else
        @records = model_class.all
        render :index, status: :unprocessable_content
      end
    end

    def destroy
      authorize @record
      @record.destroy!
      redirect_to url_for(action: :index), notice: "削除しました"
    end

    private
      def model_class = raise NotImplementedError

      def set_record
        @record = model_class.find(params[:id])
      end

      def record_params
        params.expect(model_class.model_name.param_key.to_sym => [ :name ])
      end
  end
end
