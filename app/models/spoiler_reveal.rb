class SpoilerReveal < ApplicationRecord
  belongs_to :person
  belongs_to :scenario

  validates :scenario_id, uniqueness: { scope: :person_id }
end
