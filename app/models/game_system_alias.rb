class GameSystemAlias < ApplicationRecord
  belongs_to :game_system

  validates :name, presence: true
end
