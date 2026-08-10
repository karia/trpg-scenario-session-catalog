class FavoritesController < ApplicationController
  before_action :set_scenario

  def create
    authorize @scenario, :favourite?
    add_favorite
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

    # 二重送信や競合で一意制約に当たっても結果は同じなので、押した状態にして返す。
    def add_favorite
      current_person.favorites.create!(scenario: @scenario)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      nil
    end

    def respond_with_button
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("favorite_#{@scenario.id}",
            partial: "scenarios/favorite_button", locals: { scenario: @scenario })
        end
        format.html { redirect_to scenario_path(@scenario) }
      end
    end
end
