class GroupMembership < ApplicationRecord
  belongs_to :person
  belongs_to :group

  validates :group_id, uniqueness: { scope: :person_id }
end
