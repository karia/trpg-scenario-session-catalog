module Manage
  class PlaySessionsController < BaseController
    before_action :set_play_session, only: %i[edit update destroy]

    def index
      authorize PlaySession
      # 編集者は保守のためすべての回を見る。閲覧側の Scope とは別の判断。
      @play_sessions = PlaySession.includes(:scenario, participations: :person).newest_first
    end

    def edit
      authorize @play_session
    end

    def create
      @play_session = authorize PlaySession.new(play_session_params)

      if @play_session.save
        redirect_to manage_play_sessions_path, notice: "セッションを登録しました"
      else
        @play_sessions = PlaySession.includes(:scenario).newest_first
        render :index, status: :unprocessable_content
      end
    end

    def update
      authorize @play_session

      if @play_session.update(play_session_params)
        redirect_to manage_play_sessions_path, notice: "セッションを更新しました"
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
      def set_play_session
        @play_session = PlaySession.find(params[:id])
      end

      def play_session_params
        params.expect(
          play_session: [
            :scenario_id, :played_on, :started_at, :status, :recording_url, :note,
            { participations_attributes: [ [ :id, :person_id, :role, :character_name, :character_sheet_url, :position, :_destroy ] ] }
          ]
        )
      end
  end
end
