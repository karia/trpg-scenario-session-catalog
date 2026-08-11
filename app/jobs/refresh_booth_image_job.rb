class RefreshBoothImageJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(scenario_id)
    BoothImageImporter.new(Scenario.find(scenario_id)).call(force: false)
  end
end
