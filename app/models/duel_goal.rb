class DuelGoal < ApplicationRecord
  belongs_to :duel
  belongs_to :user
  belongs_to :team

  
  # Validaciones
  validates :minute, numericality: { greater_than_or_equal_to: 0 }
end
