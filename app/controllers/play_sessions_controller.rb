class PlaySessionsController < ApplicationController
  def index
    authorize PlaySession
    @play_sessions = visible_sessions.newest_first
  end

  def show
    # 詳細も Scope から引く。同じ条件を 2 箇所に書かない。
    @play_session = visible_sessions.find(params[:id])
    authorize @play_session
  end

  private
    def visible_sessions
      policy_scope(PlaySession).includes(:scenario, participations: :person)
    end
end
