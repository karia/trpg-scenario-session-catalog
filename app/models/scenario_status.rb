class ScenarioStatus < ApplicationRecord
  belongs_to :person
  belongs_to :scenario

  validates :person_id, uniqueness: { scope: :scenario_id }
end
