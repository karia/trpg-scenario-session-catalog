class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # 権限は Person に付く。User には認証に要る情報しか持たせない。
  def pundit_user = current_person

  # 認可の書き忘れをどの環境でも落とす。要らないアクションは skip_after_action で明示的に外す。
  after_action :verify_authorized

  # 存在を伏せるため 403 ではなく 404 を返す。
  rescue_from Pundit::NotAuthorizedError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def render_not_found
    render "errors/show", status: :not_found,
      locals: { message: "ページが見つかりませんでした" }, layout: "error"
  end
end
