module Manage
  class PlaySessionsController < BaseController
    before_action :set_play_session, only: %i[edit update destroy]

    def index
      authorize PlaySession, :manage?
      # 編集者は保守のためすべての回を見る。閲覧側の Scope とは別の判断。
      @play_sessions = maintained_sessions
    end

    def edit
      authorize @play_session
    end

    def create
      @play_session = authorize PlaySession.new(play_session_params)

      if @play_session.save
        redirect_to play_session_path(@play_session), notice: "セッションを登録しました"
      else
        @play_sessions = maintained_sessions
        render :index, status: :unprocessable_content
      end
    end

    def update
      authorize @play_session

      if @play_session.update(play_session_params)
        redirect_to play_session_path(@play_session), notice: "セッションを更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @play_session
      @play_session.destroy!
      redirect_to manage_play_sessions_path, notice: "セッションを削除しました"
    end

    private
      # 保守用なので公開側の Scope は通さない。入口は require_editor と manage? で守る。
      def maintained_sessions
        PlaySession.includes(:scenario, participations: :person).newest_first
      end

      def set_play_session
        @play_session = PlaySession.find(params[:id])
      end

      def play_session_params
        permitted = params.expect(
          play_session: [
            :scenario_id, :played_on, :started_at, :status, :recording_url, :cocofolia_url, :note,
            { participations_attributes: [ [ :id, :person_id, :role, :character_name, :character_sheet_url, :position, :_destroy ] ] }
          ]
        )
        permitted.delete(:cocofolia_url) unless policy(PlaySession).update_cocofolia_url?
        permitted
      end
  end
end
