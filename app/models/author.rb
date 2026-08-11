class Author < ApplicationRecord
  DISPLAY_NAME_ATTRIBUTE = :name

  has_many :aliases, -> { order(:position, :id) }, class_name: "AuthorAlias", dependent: :destroy,
    inverse_of: :author
  include HasAliases
  has_many :scenario_authors, dependent: :destroy
  has_many :scenarios, through: :scenario_authors

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }
end
