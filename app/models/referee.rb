class Referee < ApplicationRecord
  belongs_to :user
  has_many :duels

  # Validaciones
  validates :fee, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: true
end
