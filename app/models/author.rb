class Author < ApplicationRecord
  has_many :scenario_authors, dependent: :destroy
  has_many :scenarios, through: :scenario_authors

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }
end
