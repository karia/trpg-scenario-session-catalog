class FavoritesController < ApplicationController
  before_action :set_scenario

  def create
    authorize @scenario, :favourite?
    current_person.favorites.find_or_create_by!(scenario: @scenario)
    respond_with_button
  end

  def destroy
    authorize @scenario, :favourite?
    current_person.favorites.find_by(scenario: @scenario)&.destroy
    respond_with_button
  end

  private
    def set_scenario
      @scenario = Scenario.find(params[:scenario_id])
    end

    def respond_with_button
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_#{@scenario.id}", partial: "scenarios/favorite_button", locals: { scenario: @scenario }) }
        format.html { redirect_to scenario_path(@scenario) }
      end
    end
end
