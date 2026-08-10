module Manage
  class ScenariosController < BaseController
    before_action :set_scenario, only: %i[edit update destroy]

    def index
      @scenarios = Scenario.includes(:game_systems, :authors).order(:title)
    end

    def new
      @scenario = Scenario.new
    end

    def edit
    end

    def create
      @scenario = Scenario.new(scenario_params)

      if @scenario.save
        redirect_to manage_scenarios_path, notice: "#{@scenario.title} を登録しました"
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @scenario.update(scenario_params)
        redirect_to manage_scenarios_path, notice: "#{@scenario.title} を更新しました"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @scenario.destroy!
      redirect_to manage_scenarios_path, notice: "#{@scenario.title} を削除しました"
    end

    private
      def set_scenario
        @scenario = Scenario.find(params[:id])
      end

      def scenario_params
        params.expect(
          scenario: [
            :title, :synopsis, :preparation_note, :recommendation_note,
            :recommendation, :gm_experienced, :character_restriction, :character_sheet_deadline,
            :player_count_min, :player_count_max, :player_count_note,
            :duration_min_minutes, :duration_max_minutes, :jacket,
            { game_system_ids: [], author_ids: [],
              purchase_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ],
              stream_links_attributes: [ [ :id, :label, :url, :position, :_destroy ] ] }
          ]
        )
      end
  end
end
