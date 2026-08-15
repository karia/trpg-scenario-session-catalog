class ScenariosController < ApplicationController
  before_action :set_scenario, only: %i[show edit update destroy refresh_booth_image destroy_jacket]

  def index
    @owner = Person.admins.first
    @listing = ScenarioListing.new(policy_scope(Scenario), params)
    @scenarios = @listing.scenarios.includes(:game_systems, :authors, :purchase_links,
      :scenario_statuses, jacket_attachment: :blob, booth_image_attachment: :blob)
    authorize Scenario
  end

  def show
    authorize @scenario
  end

  def new
    @scenario = authorize(Scenario.new)
    set_scenario_status
  end

  def edit
    authorize(@scenario)
    set_scenario_status
  end

  def create
    @scenario = authorize Scenario.new(scenario_params)
    set_scenario_status
    @scenario_status.assign_attributes(scenario_status_params)
    if save_scenario_and_status
      return redirect_to(@scenario, notice: "#{@scenario.title} を登録しました")
    end
    render :new, status: :unprocessable_content
  end

  def update
    authorize @scenario
    set_scenario_status
    @scenario.assign_attributes(scenario_params)
    @scenario_status.assign_attributes(scenario_status_params)
    if save_scenario_and_status
      return redirect_to(@scenario, notice: "#{@scenario.title} を更新しました")
    end
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
      params.expect(scenario: [ :title, :synopsis, :preparation_note, :recommendation_note,
        :character_restriction, :character_sheet_deadline, :character_sheet_deadline_note, :player_count_min,
        :player_count_max, :duration_min_hours, :duration_max_hours, :jacket,
        { game_system_ids: [], author_ids: [], purchase_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ],
          stream_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ] } ])
    end

    def scenario_status_params
      params.fetch(:scenario_status, ActionController::Parameters.new)
        .permit(:gm_experienced, :pl_experienced, :read)
    end

    def set_scenario_status
      @scenario_status = current_person.scenario_statuses.find_or_initialize_by(scenario: @scenario)
    end

    def save_scenario_and_status
      Scenario.transaction do
        next false unless @scenario.save

        @scenario_status.scenario = @scenario
        @scenario_status.save!
      end
    end
end
