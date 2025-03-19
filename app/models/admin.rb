class Admin < ApplicationRecord
  belongs_to :user
  belongs_to :club, optional: true
  belongs_to :clan, optional: true

  enum level, { editor: 0, admin: 1, king: 2 }

  validates :level, presence: true
end
