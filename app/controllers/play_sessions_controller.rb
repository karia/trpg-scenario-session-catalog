class PlaySessionsController < ApplicationController
  def index
    authorize PlaySession
    @play_sessions = visible_sessions.newest_first.load
  end

  def show
    @play_session = sessions_for_detail.find(params[:id])
    authorize @play_session
  end

  private
    def visible_sessions
      policy_scope(PlaySession).includes(scenario: :game_systems,
        session_schedules: :recording_links, participations: :person)
    end

    # 編集者は管理一覧と編集画面ですべての回を扱えるため、詳細も同じ範囲を許可する。
    # 公開一覧は引き続き visible_sessions を使い、表示範囲を広げない。
    def sessions_for_detail
      policy(PlaySession).manage? ?
        PlaySession.all.includes(scenario: :game_systems,
          session_schedules: :recording_links, participations: :person) :
        visible_sessions
    end
end
