class ScenarioStatus < ApplicationRecord
  belongs_to :person
  belongs_to :scenario

  validates :person_id, uniqueness: { scope: :scenario_id }

  def label
    return "#{scenario.game_master_label}経験あり" if gm_experienced?
    return "PL経験あり" if pl_experienced?
    return "シナリオ既読" if read?

    "シナリオ所持"
  end
end
