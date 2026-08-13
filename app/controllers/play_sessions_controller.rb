class PlaySessionsController < ApplicationController
  before_action :set_play_session, only: %i[show edit update destroy]

  def index
    authorize PlaySession
    @play_sessions = policy(PlaySession).manage? ? maintained_sessions : visible_sessions.newest_first.load
  end

  def show
    authorize @play_session
  end

  def new = @play_session = authorize(PlaySession.new)
  def edit = authorize(@play_session)

  def create
    @play_session = authorize PlaySession.new(play_session_params)
    return redirect_to(@play_session, notice: "セッションを登録しました") if @play_session.save
    render :new, status: :unprocessable_content
  end

  def update
    authorize @play_session
    return redirect_to(@play_session, notice: "セッションを更新しました") if @play_session.update(play_session_params)
    render :edit, status: :unprocessable_content
  end

  def destroy
    authorize @play_session
    @play_session.destroy!
    redirect_to play_sessions_path, notice: "セッションを削除しました"
  end

  private
    def visible_sessions
      policy_scope(PlaySession).includes(scenario: :game_systems,
        session_schedules: :recording_links, participations: :person)
    end

    def maintained_sessions
      PlaySession.includes(:scenario, :session_schedules, participations: :person).newest_first
    end

    def set_play_session = @play_session = sessions_for_detail.find(params[:id])

    def play_session_params
      permitted = params.expect(play_session: [ :scenario_id, :cocofolia_url, :note,
        { session_schedules_attributes: [ [ :id, :scheduled_on, :started_at, :position, :_destroy,
          { recording_links_attributes: [ [ :id, :url, :position, :_destroy ] ] } ] ] },
        { participations_attributes: [ [ :id, :person_id, :role, :character_name, :character_sheet_url, :position, :_destroy ] ] } ])
      permitted.delete(:cocofolia_url) unless policy(PlaySession).update_cocofolia_url?
      permitted
    end

    # 編集者は統合した一覧と編集画面ですべての回を扱えるため、詳細も同じ範囲を許可する。
    def sessions_for_detail
      policy(PlaySession).manage? ?
        PlaySession.all.includes(scenario: :game_systems,
          session_schedules: :recording_links, participations: :person) :
        visible_sessions
    end
end
