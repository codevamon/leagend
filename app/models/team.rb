class Team < ApplicationRecord
  belongs_to :club, optional: true
  belongs_to :clan, optional: true
  has_many :team_memberships
  has_many :users, through: :team_memberships
  has_many :home_duels, class_name: 'Duel', foreign_key: 'home_team_id'
  has_many :away_duels, class_name: 'Duel', foreign_key: 'away_team_id'
  has_many :callups, dependent: :destroy
  has_many :called_up_users, through: :callups, source: :user

  def duels
    Duel.where("home_team_id = ? OR away_team_id = ?", id, id)
  end
  
  # Métodos para estadísticas unificadas
  def wins
    results.where(outcome: 'win').count
  end

  def losses
    results.where(outcome: 'loss').count
  end

  def draws
    results.where(outcome: 'draw').count
  end
  
  def leader
    team_memberships.find_by(leader: true)&.user
  end
end
