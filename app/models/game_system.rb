class GameSystem < ApplicationRecord
  has_many :scenario_game_systems, dependent: :destroy
  has_many :scenarios, through: :scenario_game_systems

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }
end
