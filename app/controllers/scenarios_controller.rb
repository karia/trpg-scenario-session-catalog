class ScenariosController < ApplicationController
  VIEWS = %w[table gallery].freeze

  def index
    @view = VIEWS.include?(params[:view]) ? params[:view] : VIEWS.first
    @scenarios = policy_scope(Scenario)
      .includes(:game_systems, :authors, :purchase_links, jacket_attachment: :blob)
      .recommended_first
    authorize Scenario
  end

  def show
    @scenario = policy_scope(Scenario).includes(:game_systems, :authors, :purchase_links, :stream_links).find(params[:id])
    authorize @scenario
  end
end
