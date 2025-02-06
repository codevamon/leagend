class Duel < ApplicationRecord
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'
  belongs_to :referee, optional: true
  has_many :results
  has_many :lineups
  has_many :home_players, through: :lineups, source: :user, conditions: { lineups: { team_id: home_team_id } }
  has_many :away_players, through: :lineups, source: :user, conditions: { lineups: { team_id: away_team_id } }
  has_many :duel_goals
  has_many :scorers, through: :duel_goals, source: :user


  # Enums
  enum status: { pending: 0, in_progress: 1, completed: 2 }
  enum duel_type: { friendly: 0, bet: 1 }

  # Campos adicionales
  attribute :price, :decimal, default: 0.0
  attribute :budget, :decimal, default: 0.0
  attribute :referee_fee, :decimal, default: 0.0

  # Validaciones
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :budget, numericality: { greater_than_or_equal_to: 0 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date


  
  # Métodos
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    if end_date <= start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  # Método para calcular el total de goles
  # def total_goals
  #   home_goals + away_goals
  # end

  
  # Método para calcular el total de goles
  def total_goals
    duel_goals.count
  end

  # Método para calcular los goles por equipo
  def goals_by_team(team)
    duel_goals.where(team: team).count
  end
end
