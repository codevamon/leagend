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
    lineups.where(teamable: home_team).includes(:user).map(&:user)
  end

  def away_players
    away_team ? lineups.where(teamable: away_team).includes(:user).map(&:user) : []
  end

  # Enums
  enum :status, { 
    pending: 0,    # Pendiente de confirmación
    open: 1,       # Abierto para desafíos
    ongoing: 2,    # En curso
    finished: 3,   # Finalizado
    merged: 4,     # Fusionado con otro duelo
    cancelled: 5,  # Cancelado
    postponed: 6   # Postergado
  }

  enum :duel_type, { 
    friendly: 0,   # Amistoso
    bet: 1,        # Apuesta (deshabilitado)
    rematch: 2,    # Revancha
    training: 3,   # Entrenamiento
    hobbie: 4      # Recocha
  }

  enum :challenge_type, { 
    challengee: 0,  # Desafiado
    challenger: 1,  # Desafiante
    direct: 2       # Directo
  }

  # Defaults (útiles en caso de usar `attribute`)
  attribute :price, :decimal, default: 0.0
  attribute :budget, :decimal, default: 0.0
  attribute :referee_fee, :decimal, default: 0.0
  attribute :temporary, :boolean, default: true

  # Validaciones
  validates :starts_at, :ends_at, presence: true
  validates :price, :budget, :referee_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :duel_type, presence: true
  validate :end_date_after_start_date
  
  validate :arena_availability, if: -> { arena.present? && starts_at.present? && ends_at.present? }
  validate :validate_team_sizes, if: -> { home_team.present? && away_team.present? }
  validate :validate_duel_type, if: -> { duel_type.present? }


  # UUID
  before_create :generate_uuid
  before_save :set_expires_at, if: :temporary?
  after_save :notify_status_change, if: :saved_change_to_status?

  # Scopes
  scope :active, -> { where(status: [:pending, :open, :ongoing]) }
  scope :finished, -> { where(status: :finished) }
  scope :cancelled, -> { where(status: :cancelled) }
  scope :upcoming, -> { where("starts_at > ?", Time.current) }
  scope :past, -> { where("ends_at < ?", Time.current) }
  scope :needs_attention, -> { 
    where(status: :pending)
    .where("starts_at < ?", 2.hours.from_now)
    .where("EXISTS (SELECT 1 FROM callups WHERE callups.duel_id = duels.id AND callups.status = 'pending')")
  }

  # Métodos de Estado
  def can_start?
    return false unless status.in?(['pending', 'open'])
    return false if starts_at > Time.current
    return false unless has_minimum_players?
    true
  end

  def can_be_challenged?
    arena.present? && away_team_id.nil? && status == "open"
  end

  def can_randomize_teams?
    return false unless status.in?(['pending', 'open'])
    return false if starts_at < Time.current
    return false if home_players.count >= required_players
    true
  end

  def can_be_postponed?
    return false unless status.in?(['pending', 'open'])
    return false if starts_at < Time.current
    true
  end

  def can_be_cancelled?
    return false if status.in?(['finished', 'cancelled', 'merged'])
    return false if starts_at < Time.current
    true
  end

  def needs_attention?
    return false unless status == 'pending'
    return false if starts_at > 2.hours.from_now
    pending_callups.any?
  end

  def status_color
    case status
    when 'pending' then 'warning'
    when 'open' then 'info'
    when 'ongoing' then 'primary'
    when 'finished' then 'success'
    when 'cancelled' then 'danger'
    when 'postponed' then 'secondary'
    else 'light'
    end
  end

  # Métodos de Jugadores
  def home_players
    lineups.where(teamable: home_team).includes(:user).map(&:user)
  end

  def away_players
    away_team ? lineups.where(teamable: away_team).includes(:user).map(&:user) : []
  end

  def pending_callups
    callups.pending.includes(:user)
  end

  def free_players
    User.where.not(id: home_players.pluck(:id))
        .where.not(id: away_players.pluck(:id))
        .where.not(id: pending_callups.pluck(:user_id))
  end

  def possible_duel_types
    [5, 7, 11] # Tipos de duelo posibles
  end

  def required_players
    case duel_type
    when 'friendly' then 5
    when 'training' then 7
    when 'hobbie' then 11
    else 5
    end
  end

  def has_minimum_players?
    home_players.count >= required_players && 
    (away_team.nil? || away_players.count >= required_players)
  end

  # --- MVP FLUJO DE DUELOS ---

  # ¿El duelo está caducado?
  def expired?
    temporary? && expires_at.present? && Time.current > expires_at
  end

  # ¿Es desafiable?
  def desafiable?
    challenge_type == "challengee" && arena.nil? && away_team_id.nil?
  end

  # ¿Es desafiante?
  def desafiante?
    challenge_type == "challenger" && arena.present? && away_team_id.nil?
  end

  # ¿Permite llenar cupo con jugadores libres?
  def allows_freeplayers?
    status.in?(["pending", "open"]) && !expired? && !has_minimum_players?
  end

  # Scope para Explore
  scope :open_for_freeplayers, -> { where(status: [:pending, :open], temporary: true).where('expires_at > ?', Time.current) }

  def can_be_managed_by?(user)
    home_team&.captain == user || away_team&.captain == user
  end

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end

    def end_date_after_start_date
      return if ends_at.blank? || starts_at.blank?
      if ends_at <= starts_at
        errors.add(:ends_at, "debe ser posterior a la hora de inicio")
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
        errors.add(:arena, "no está disponible en ese horario")
      end
    end

    def validate_team_sizes
      if home_players.count > required_players || (away_team && away_players.count > required_players)
        errors.add(:base, "Los equipos exceden el número máximo de jugadores")
      end
    end

    def validate_duel_type
      if duel_type == 'bet' && !Rails.application.config.enable_betting
        errors.add(:duel_type, "Las apuestas están deshabilitadas")
      end
    end

    def set_expires_at
      self.expires_at = starts_at + 24.hours if expires_at.nil?
    end

    def notify_status_change
      NotificationService.notify_duel_updated(self)
    end
end
