class ScenariosController < ApplicationController
  before_action :set_scenario, only: %i[show edit update destroy refresh_booth_image destroy_jacket]

  def index
    @listing = ScenarioListing.new(policy_scope(Scenario), params)
    @scenarios = @listing.scenarios.includes(:game_systems, :authors, :purchase_links,
      jacket_attachment: :blob, booth_image_attachment: :blob)
    authorize Scenario
  end

  def show
    authorize @scenario
  end

  def new = @scenario = authorize(Scenario.new)

  def edit = authorize(@scenario)

  def create
    @scenario = authorize Scenario.new(scenario_params)
    return redirect_to(@scenario, notice: "#{@scenario.title} を登録しました") if @scenario.save
    render :new, status: :unprocessable_content
  end

  def update
    authorize @scenario
    return redirect_to(@scenario, notice: "#{@scenario.title} を更新しました") if @scenario.update(scenario_params)
    render :edit, status: :unprocessable_content
  end

  def destroy
    authorize @scenario
    return redirect_to(scenarios_path, notice: "#{@scenario.title} を削除しました") if @scenario.destroy
    redirect_to scenarios_path, alert: @scenario.errors.full_messages.join("、")
  end

  def refresh_booth_image
    authorize @scenario, :update?
    result = BoothImageImporter.new(@scenario).call(force: true)
    redirect_to edit_scenario_path(@scenario), (result.success? ? { notice: result.message } : { alert: result.message })
  end

  def destroy_jacket
    authorize @scenario, :update?
    @scenario.jacket.purge
    redirect_to edit_scenario_path(@scenario), notice: "ジャケット画像を削除しました"
  end

  private
    def set_scenario
      @scenario = policy_scope(Scenario).includes(:game_systems, :authors, :purchase_links, :stream_links,
        jacket_attachment: :blob, booth_image_attachment: :blob).find(params[:id])
    end

    def scenario_params
      params.expect(scenario: [ :title, :synopsis, :preparation_note, :recommendation_note, :gm_experienced,
        :character_restriction, :character_sheet_deadline, :character_sheet_deadline_note, :player_count_min,
        :player_count_max, :duration_min_hours, :duration_max_hours, :jacket,
        { game_system_ids: [], author_ids: [], purchase_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ],
          stream_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ] } ])
    end
end
