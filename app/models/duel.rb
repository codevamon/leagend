class Duel < ApplicationRecord
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team', optional: true
  belongs_to :referee, class_name: 'User', optional: true
  belongs_to :man_of_the_match, class_name: 'User', optional: true
  belongs_to :arena, optional: true

  has_one :result
  
  has_many :callups
  has_many :lineups
  has_many :duel_goals
  has_many :scorers, through: :duel_goals, source: :User
  has_many :challenges_as_challenger, class_name: "Challenge", foreign_key: :challenger_duel_id
  has_many :challenges_as_challengee, class_name: "Challenge", foreign_key: :challengee_duel_id


  # Relación filtrada manualmente (condiciones en métodos, no en `has_many`)
  def home_players
    lineups.where(team_id: home_team_id).map(&:user)
  end

  def away_players
    lineups.where(team_id: away_team_id).map(&:user)
  end

  # Enums
  enum :status, { open: 0, ongoing: 1, finished: 2, merged: 3, cancelled: 4, postponed:5 }
  enum :duel_type, { friendly: 0, bet: 1, rematch: 2, training: 3 }
  enum :challenge, { challengee: 0, challenger: 1, challenged: 2 }

  # Defaults (útiles en caso de usar `attribute`)
  attribute :price, :decimal, default: 0.0
  attribute :budget, :decimal, default: 0.0
  attribute :referee_fee, :decimal, default: 0.0

  # Validaciones
  validates :starts_at, :ends_at, presence: true
  validates :price, :budget, numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_after_start_date
  
  validate :arena_availability, if: -> { arena.present? && starts_at.present? && ends_at.present? }


  # UUID
  before_create :generate_uuid


  

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end

    def end_date_after_start_date
      return if ends_at.blank? || starts_at.blank?
      if ends_at <= starts_at
        errors.add(:ends_at, "must be after the start time")
      end
    end

    # Goles
    def total_goals
      duel_goals.count
    end

    def goals_by_team(team)
      duel_goals.where(team: team).count
    end
    
    def arena_availability
      unless arena.available_between?(starts_at, ends_at)
        errors.add(:arena, "is not available in that time slot")
      end
    end
end
