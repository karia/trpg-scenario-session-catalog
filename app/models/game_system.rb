class GameSystem < ApplicationRecord
  DISPLAY_NAME_ATTRIBUTE = :name

  has_many :aliases, -> { order(:position, :id) }, class_name: "GameSystemAlias", dependent: :destroy,
    inverse_of: :game_system
  include HasAliases
  has_many :scenario_game_systems, dependent: :destroy
  has_many :scenarios, through: :scenario_game_systems

  validates :name, presence: true, uniqueness: true
  normalizes :game_master_label, with: ->(value) { value.strip.presence }

  default_scope { order(:name) }
end
