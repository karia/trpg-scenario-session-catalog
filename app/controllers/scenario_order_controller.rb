class ScenarioOrderController < ApplicationController
  before_action :set_scenario, only: :move

  def index
    authorize Scenario, :reorder?
    @scenarios = Scenario.includes(:game_systems, :authors).gm_ordered
  end

  def reorder
    authorize Scenario, :reorder?
    Scenario.rearrange(Array(params.permit(scenario_ids: [])[:scenario_ids]).map(&:to_i))
    head :no_content
  end

  def move
    authorize @scenario, :reorder?
    @scenario.move(params[:direction].to_s)
    @scenarios = Scenario.includes(:game_systems, :authors).gm_ordered
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("scenario_order", partial: "scenario_order/scenarios", locals: { scenarios: @scenarios }) }
      format.html { redirect_to scenario_order_index_path }
    end
  end

  private
    def set_scenario = @scenario = Scenario.find(params[:id])
end
