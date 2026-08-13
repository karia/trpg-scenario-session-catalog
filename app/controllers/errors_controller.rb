class ErrorsController < ActionController::Base
  def show
    status = params[:code].to_i
    message = status < 500 ? "ページが見つかりませんでした" : "サーバーでエラーが発生しました"

    render status:, locals: { message: }, layout: "error"
  end
end
