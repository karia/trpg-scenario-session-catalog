class ScenariosController < ApplicationController
  def index
    @listing = ScenarioListing.new(policy_scope(Scenario), params)
    @scenarios = @listing.scenarios.includes(:game_systems, :authors, :purchase_links,
      jacket_attachment: :blob, booth_image_attachment: :blob)
    authorize Scenario
  end

  def show
    @scenario = policy_scope(Scenario).includes(:game_systems, :authors, :purchase_links, :stream_links,
      jacket_attachment: :blob, booth_image_attachment: :blob).find(params[:id])
    authorize @scenario
  end
end
