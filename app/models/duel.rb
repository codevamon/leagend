class Duel < ApplicationRecord
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'
  belongs_to :referee, class_name: 'User', optional: true
  belongs_to :man_of_the_match, class_name: 'User', optional: true

  has_many :results
  has_many :lineups
  has_many :duel_goals
  has_many :scorers, through: :duel_goals, source: :user

  # Relación filtrada manualmente (condiciones en métodos, no en `has_many`)
  def home_players
    lineups.where(team_id: home_team_id).map(&:user)
  end

  def away_players
    lineups.where(team_id: away_team_id).map(&:user)
  end

  # Enums
  enum status: { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }
  enum duel_type: { friendly: 0, bet: 1, rematch: 2 }

  # Defaults (útiles en caso de usar `attribute`)
  attribute :price, :decimal, default: 0.0
  attribute :budget, :decimal, default: 0.0
  attribute :referee_fee, :decimal, default: 0.0

  # Validaciones
  validates :start_date, :end_date, presence: true
  validates :price, :budget, numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_after_start_date

  # UUID
  before_create :generate_uuid

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end

    def end_date_after_start_date
      return if end_date.blank? || start_date.blank?
      if end_date <= start_date
        errors.add(:end_date, "must be after the start date")
      end
    end

    # Goles
    def total_goals
      duel_goals.count
    end

    def goals_by_team(team)
      duel_goals.where(team: team).count
    end
end
