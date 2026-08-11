class GameSystemAlias < ApplicationRecord
  attr_accessor :selection_key

  belongs_to :game_system

  validates :name, presence: true
end
