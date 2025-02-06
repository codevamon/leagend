class Lineup < ApplicationRecord
  belongs_to :duel
  belongs_to :team
  belongs_to :user

  # Campos adicionales: posición, número de camiseta, etc.
  validates :user_id, uniqueness: { scope: [:duel_id, :team_id], message: "can only be in one lineup per duel" }
end
