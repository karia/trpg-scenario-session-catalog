class ScenarioGameSystem < ApplicationRecord
  belongs_to :scenario
  belongs_to :game_system

  validates :game_system_id, uniqueness: { scope: :scenario_id }
end
