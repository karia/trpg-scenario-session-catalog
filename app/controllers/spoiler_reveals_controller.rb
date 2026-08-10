class SpoilerRevealsController < ApplicationController
  # 押した記録は Person に紐づける。端末を変えても開いたままになる。
  def create
    @scenario = Scenario.find(params[:scenario_id])
    authorize @scenario, :reveal_preparation_note?
    current_person.spoiler_reveals.find_or_create_by!(scenario: @scenario)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("preparation_note_#{@scenario.id}", partial: "scenarios/preparation_note", locals: { scenario: @scenario }) }
      format.html { redirect_to scenario_path(@scenario) }
    end
  end
end
