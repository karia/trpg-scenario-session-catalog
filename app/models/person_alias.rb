class PersonAlias < ApplicationRecord
  attr_accessor :selection_key

  belongs_to :person

  validates :name, presence: true
end
