module Manage
  class ScenariosController < BaseController
    before_action :set_scenario, only: %i[edit update destroy move refresh_booth_image destroy_jacket]

    def index
      authorize Scenario, :manage?
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
      redirect_to manage_scenarios_path
    end

    def refresh_booth_image
      authorize @scenario, :update?
      result = BoothImageImporter.new(@scenario).call(force: true)
      redirect_to edit_manage_scenario_path(@scenario), (result.success? ? { notice: result.message } : { alert: result.message })
    end

    def destroy_jacket
      authorize @scenario, :update?
      @scenario.jacket.purge
      redirect_to edit_manage_scenario_path(@scenario), notice: "ジャケット画像を削除しました"
    end

    def new
      @scenario = authorize Scenario.new
    end

    def edit
      authorize @scenario
    end

    def create
      @scenario = authorize Scenario.new(scenario_params)

      if @scenario.save
        redirect_to manage_scenarios_path, notice: "#{@scenario.title} を登録しました"
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @scenario

      if @scenario.update(scenario_params)
        redirect_to manage_scenarios_path, notice: "#{@scenario.title} を更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @scenario

      if @scenario.destroy
        redirect_to manage_scenarios_path, notice: "#{@scenario.title} を削除しました"
      else
        redirect_to manage_scenarios_path, alert: @scenario.errors.full_messages.join("、")
      end
    end

    private
      def set_scenario
        @scenario = Scenario.find(params[:id])
      end

      def scenario_params
        params.expect(
          scenario: [
            :title, :synopsis, :preparation_note, :recommendation_note,
            :gm_experienced, :character_restriction, :character_sheet_deadline, :character_sheet_deadline_note,
            :player_count_min, :player_count_max,
            :duration_min_hours, :duration_max_hours, :jacket,
            { game_system_ids: [], author_ids: [],
              purchase_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ],
              stream_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ] }
          ]
        )
      end
  end
end
