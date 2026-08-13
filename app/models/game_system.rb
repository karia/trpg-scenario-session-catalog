class GameSystem < ApplicationRecord
  DISPLAY_NAME_ATTRIBUTE = :name
  DEFAULT_GAME_MASTER_LABEL = "GM"
  DEFAULT_ROLE_LABELS = {
    gm: DEFAULT_GAME_MASTER_LABEL,
    sub_gm: "サブ#{DEFAULT_GAME_MASTER_LABEL}"
  }.freeze

  has_many :aliases, -> { order(:position, :id) }, class_name: "GameSystemAlias", dependent: :destroy,
    inverse_of: :game_system
  include HasAliases
  has_many :scenario_game_systems, dependent: :destroy
  has_many :scenarios, through: :scenario_game_systems

  validates :name, presence: true, uniqueness: true
  normalizes :game_master_label, with: ->(value) { value.strip.presence }

  default_scope { order(:name) }
end
