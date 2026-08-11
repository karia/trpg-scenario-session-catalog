class AuthorAlias < ApplicationRecord
  attr_accessor :selection_key

  belongs_to :author

  validates :name, presence: true
end
