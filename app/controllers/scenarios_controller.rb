class ScenariosController < ApplicationController
  def index
    @scenarios = policy_scope(Scenario).includes(:game_systems, :authors, jacket_attachment: :blob)
    authorize Scenario
  end

  def show
    @scenario = policy_scope(Scenario).includes(:game_systems, :authors, :purchase_links, :stream_links).find(params[:id])
    authorize @scenario
  end
end
