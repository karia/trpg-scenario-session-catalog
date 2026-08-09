class ScenarioAuthor < ApplicationRecord
  belongs_to :scenario
  belongs_to :author

  validates :author_id, uniqueness: { scope: :scenario_id }
end
